// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library classify;

import 'package:html5lib/src/token.dart';
import 'package:html5lib/src/tokenizer.dart';
import '../../markdown.dart';
import 'dart.dart';

class Classification {
  static const NONE = "";
  static const ERROR = "e";
  static const COMMENT = "c";
  static const IDENTIFIER = "i";
  static const KEYWORD = "k";
  static const OPERATOR = "o";
  static const STRING = "s";
  static const NUMBER = "n";
  static const PUNCTUATION = "p";
  static const TYPE_IDENTIFIER = "t";
  static const SPECIAL_IDENTIFIER = "r";
  static const ARROW_OPERATOR = "a";
  static const STRING_INTERPOLATION = 'si';
}

String classifyHtml(String src) {
  var out = new StringBuffer();
  var tokenizer = new HtmlTokenizer(src, 'utf8', true, true, true, true);
  var syntax = '';
  
  while (tokenizer.moveNext()) {
    var token = tokenizer.current;
    var classification = Classification.NONE;
    
    switch (token.kind)
    {
      case TokenKind.characters:
        var chars = token.span.text;
        if (syntax == 'dart') {
          chars = classifyDart(chars);
        } else {
          chars = escapeHtml(chars);
        }
        out.add(chars);
        syntax = '';
      continue;
      case TokenKind.comment:
        classification = Classification.COMMENT;
      break;
      case TokenKind.doctype:
        classification = Classification.COMMENT;
      break;
        
      case TokenKind.startTag:
        addTag(out, token);
        if (token.name == 'script') {
          token.data.forEach((pair) {
            if (pair[0] == 'type' && pair[1] == 'application/dart') {
              syntax = 'dart';
            }
          });
        }
      continue;
      
      case TokenKind.endTag:
        addTag(out, token);
      continue;
      
      case TokenKind.parseError:
        classification = Classification.ERROR;
      break;
      case TokenKind.spaceCharacters:
        classification = Classification.NONE;
      break;
    }
    var str = escapeHtml(token.span.text);
    out.add('<span class="$classification">$str</span>');
  }
  
  return out.toString();
}

final _RE_ATTR = new RegExp(r'( +[\w\-]+)( *= *)?(".+?")?');

String addTag(StringBuffer buf, TagToken token) {
  var start = token.kind == TokenKind.endTag ? 2 : 1;
  var end = token.selfClosing ? 2 : 1;
  var text = token.span.text;
  
  // Add the start of the tag.
  buf.add(escapeHtml(text.substring(0, start)));
  
  // Add the tag name.
  addSpan(buf, Classification.TYPE_IDENTIFIER, token.name);
  
  // Add the tag attributes.
  var content = text.substring(start, text.length - end);
  _RE_ATTR.allMatches(content).forEach((match) {
    addSpan(buf, Classification.KEYWORD, match[1]);
    if (match[2] != null) buf.add(match[2]);
    if (match[3] != null) {
      addSpan(buf, Classification.STRING, match[3]);
    }
  });
  
  // Add the end of the tag.
  buf.add(escapeHtml(text.substring(text.length - end, text.length)));
}

String addSpan(StringBuffer buffer, String cls, String text) {
  buffer.add('<span class="$cls">${escapeHtml(text)}</span>');
}
