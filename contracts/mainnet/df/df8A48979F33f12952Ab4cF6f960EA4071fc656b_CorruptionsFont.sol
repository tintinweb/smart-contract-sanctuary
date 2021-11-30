// SPDX-License-Identifier: Unlicense
// might change to something more "custom" in the future but this will do for now

pragma solidity ^0.8.1;

contract CorruptionsFont {
    // based off the very excellent PT Mono font

    /*
    Copyright (c) 2011, ParaType Ltd. (http://www.paratype.com/public),
    with Reserved Font Names "PT Sans", "PT Serif", "PT Mono" and "ParaType".

    This Font Software is licensed under the SIL Open Font License, Version 1.1.
    This license is copied below, and is also available with a FAQ at:
    http://scripts.sil.org/OFL


    -----------------------------------------------------------
    SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
    -----------------------------------------------------------

    PREAMBLE
    The goals of the Open Font License (OFL) are to stimulate worldwide
    development of collaborative font projects, to support the font creation
    efforts of academic and linguistic communities, and to provide a free and
    open framework in which fonts may be shared and improved in partnership
    with others.

    The OFL allows the licensed fonts to be used, studied, modified and
    redistributed freely as long as they are not sold by themselves. The
    fonts, including any derivative works, can be bundled, embedded, 
    redistributed and/or sold with any software provided that any reserved
    names are not used by derivative works. The fonts and derivatives,
    however, cannot be released under any other type of license. The
    requirement for fonts to remain under this license does not apply
    to any document created using the fonts or their derivatives.

    DEFINITIONS
    "Font Software" refers to the set of files released by the Copyright
    Holder(s) under this license and clearly marked as such. This may
    include source files, build scripts and documentation.

    "Reserved Font Name" refers to any names specified as such after the
    copyright statement(s).

    "Original Version" refers to the collection of Font Software components as
    distributed by the Copyright Holder(s).

    "Modified Version" refers to any derivative made by adding to, deleting,
    or substituting -- in part or in whole -- any of the components of the
    Original Version, by changing formats or by porting the Font Software to a
    new environment.

    "Author" refers to any designer, engineer, programmer, technical
    writer or other person who contributed to the Font Software.

    PERMISSION & CONDITIONS
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of the Font Software, to use, study, copy, merge, embed, modify,
    redistribute, and sell modified and unmodified copies of the Font
    Software, subject to the following conditions:

    1) Neither the Font Software nor any of its individual components,
    in Original or Modified Versions, may be sold by itself.

    2) Original or Modified Versions of the Font Software may be bundled,
    redistributed and/or sold with any software, provided that each copy
    contains the above copyright notice and this license. These can be
    included either as stand-alone text files, human-readable headers or
    in the appropriate machine-readable metadata fields within text or
    binary files as long as those fields can be easily viewed by the user.

    3) No Modified Version of the Font Software may use the Reserved Font
    Name(s) unless explicit written permission is granted by the corresponding
    Copyright Holder. This restriction only applies to the primary font name as
    presented to the users.

    4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
    Software shall not be used to promote, endorse or advertise any
    Modified Version, except to acknowledge the contribution(s) of the
    Copyright Holder(s) and the Author(s) or with their explicit written
    permission.

    5) The Font Software, modified or unmodified, in part or in whole,
    must be distributed entirely under this license, and must not be
    distributed under any other license. The requirement for fonts to
    remain under this license does not apply to any document created
    using the Font Software.

    TERMINATION
    This license becomes null and void if any of the above conditions are
    not met.

    DISCLAIMER
    THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
    OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
    DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
    OTHER DEALINGS IN THE FONT SOFTWARE.
    */

    string public constant font = "data:font/otf;base64,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";
}