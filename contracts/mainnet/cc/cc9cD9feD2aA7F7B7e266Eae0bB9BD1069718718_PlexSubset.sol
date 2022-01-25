// Copyright © 2017 IBM Corp. with Reserved Font Name "Plex"

// This Font Software is licensed under the SIL Open Font License, Version 1.1.

// This license is copied below, and is also available with a FAQ at: http://scripts.sil.org/OFL


// -----------------------------------------------------------
// SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
// -----------------------------------------------------------

// PREAMBLE
// The goals of the Open Font License (OFL) are to stimulate worldwide
// development of collaborative font projects, to support the font creation
// efforts of academic and linguistic communities, and to provide a free and
// open framework in which fonts may be shared and improved in partnership
// with others.

// The OFL allows the licensed fonts to be used, studied, modified and
// redistributed freely as long as they are not sold by themselves. The
// fonts, including any derivative works, can be bundled, embedded, 
// redistributed and/or sold with any software provided that any reserved
// names are not used by derivative works. The fonts and derivatives,
// however, cannot be released under any other type of license. The
// requirement for fonts to remain under this license does not apply
// to any document created using the fonts or their derivatives.

// DEFINITIONS
// "Font Software" refers to the set of files released by the Copyright
// Holder(s) under this license and clearly marked as such. This may
// include source files, build scripts and documentation.

// "Reserved Font Name" refers to any names specified as such after the
// copyright statement(s).

// "Original Version" refers to the collection of Font Software components as
// distributed by the Copyright Holder(s).

// "Modified Version" refers to any derivative made by adding to, deleting,
// or substituting -- in part or in whole -- any of the components of the
// Original Version, by changing formats or by porting the Font Software to a
// new environment.

// "Author" refers to any designer, engineer, programmer, technical
// writer or other person who contributed to the Font Software.

// PERMISSION & CONDITIONS
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of the Font Software, to use, study, copy, merge, embed, modify,
// redistribute, and sell modified and unmodified copies of the Font
// Software, subject to the following conditions:

// 1) Neither the Font Software nor any of its individual components,
// in Original or Modified Versions, may be sold by itself.

// 2) Original or Modified Versions of the Font Software may be bundled,
// redistributed and/or sold with any software, provided that each copy
// contains the above copyright notice and this license. These can be
// included either as stand-alone text files, human-readable headers or
// in the appropriate machine-readable metadata fields within text or
// binary files as long as those fields can be easily viewed by the user.

// 3) No Modified Version of the Font Software may use the Reserved Font
// Name(s) unless explicit written permission is granted by the corresponding
// Copyright Holder. This restriction only applies to the primary font name as
// presented to the users.

// 4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
// Software shall not be used to promote, endorse or advertise any
// Modified Version, except to acknowledge the contribution(s) of the
// Copyright Holder(s) and the Author(s) or with their explicit written
// permission.

// 5) The Font Software, modified or unmodified, in part or in whole,
// must be distributed entirely under this license, and must not be
// distributed under any other license. The requirement for fonts to
// remain under this license does not apply to any document created
// using the Font Software.

// TERMINATION
// This license becomes null and void if any of the above conditions are
// not met.

// DISCLAIMER
// THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
// OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
// COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
// DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
// OTHER DEALINGS IN THE FONT SOFTWARE.
pragma solidity >=0.8.0 <0.9.0;

library PlexSubset {
  function getIBMPlexMonoSubset() public pure returns (string memory) {
    return IBMPlexMonoSubset;
  }
  
  function getIBMPlexSansCondensedSubset() public pure returns (string memory) {
    return IBMPlexSansCondensedSubset;
  }
  
  function getIBMPlexMonoSubsetUnicodeRange() public pure returns (string memory) {
    return IBMPlexMonoSubset;
  }
  
  function getIBMPlexSansCondensedSubsetUnicodeRange() public pure returns (string memory) {
    return IBMPlexSansCondensedSubsetUnicodeRange;
  }
  
  string private constant IBMPlexSansCondensedSubsetUnicodeRange = "U+20,U+23,U+30-39,U+45-47,U+4d,U+4f,U+52-53,U+56";
  
  string private constant IBMPlexSansCondensedSubset = "data:font/woff2;base64,d09GMgABAAAAABC4ABEAAAAAK1AAABBdAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGhYbjE4cgWAGYABsCDwJgnMREAq3WLI4C1QAATYCJAN+BCAFgn4HIAyDGBs0J7MRUVMkX9bI/ssDnozXTjn4stNuLCIkqjVMVFFrqWrBwEgewnZHbiCGGHc2VeOZ4fgbwxfXslrH4aSMn/OIwxGSzPqPOv89V5JlW7YTJcbITuIAfQTcSrhmbnkDHLZ2fP8VcC5vxBPQ+jPwbut3RmPmtKlwCCNHtPYcOSwqbfCikMuorxddX5U8T7/2O7uYvd8IXcRLwBPNpBQqrWgJOx0Nncy1cql7Isju0pi5U5vV1KpLbwDFME0MXdj+Qx4A8/PrvCHFlbBQyxKIBKUj34f8pzVtfsvv7VYBogSggTSTEssT6mxWqDtWgOSAB8+NcSIbAOVbK3CV/pfNMp33WyM44ywYWAccunLV7HJmTg9CB0lr1CXNV6t3tFqDdFNzRDrmMRCF68xBSMiVAwYRp84chXaakVq4XfY2Rwp04iXoy1yVrIhWNFCaa1i1+d+fGATwAQDAEMZFCKAss0vK7oJ+EKg+vz4ZAPIJAGYKoc1qADu7jVhqNgjQaHwQDCDqj51N4sjHKkAAnUg+LBnMKMwYAGAhERGgEcHChQgA7IudAyFAZFwAIDUkbeBoGaAocElbxpJLdYXSiXZIw8I5UAYujBMRVoTGUHCMphOWNNt7Ulsj3C6Q6Tyu6YQHiwFrbUGyOdI0B1KYnLwEAfDOxDyhGpulKsC5IkqdJgkVPkblWChkuOzWHY8AeMkTqjjMHDkQlyQtDZWYhoeBNMqqEyErlpJWoQ5uMAsBov49XbFEKtNg5ApNLR1DY7MMHWMyUhk//OQqbAGPwCkuRgIAHwAAgAOwMBsIwCV6mTjssz2USNPepUDlkYmtrdTV0zcwMg5MszjQcpvEWUAfHVlDAJL6d3eCbWI+N+rUjsSy6A95IsdoVhwiEYhqcdvX+ADPeYReCj5yAFfWTmz8Rihu5soQnXDdIL1Q/XCDMMMII8WYHQoTzggWJgQkCMBhVOOqPeMS3FlxVxq9OCQwB5TIjGQMU10KCI52dcGALWAM18MAEA5h88kEggxtfSODkBQHm0NqGgomjtotBdpy1gz0AtqSAzEeh1QjSATB0FergyjJHUjDZaEawmZEzgWxpBmmpcZOxVnGwoAEABzGmzASB0s4fY8zc0kjDjNK0goyGBJVGmaUTmm4ULkLGWUcBsBypYGxIIIoyHQQWyLNDNaqGIlE6yCBZFcDme4eyDF2GmR+8GYmwIwBMTp95LHSaULgGYBizYiLi+El01JcJmIEckwh0qS0KG2BP5qLTra62eilp5+VQbqGuRtlYpw5LWZLcClLxlJog+OJP3TYWOOBLQy8zf9O0r7OA2714NfkLHcF18h1Tt+CfoAz2/UffuwNUCa7fNgfAdpuCaBz1oCmcUaHRNV8Pzu45hLKNWaHMtJjX14gdf27EhgSa8FqeNsY9ELJC3OU8OFFndKv4MAeGQYABxcPSCcwVF0A65PSYhzXWwKk/p7s3zaAIgHoTFverCYUsYTCEvQEAKybzQMoywWOSNPCEc69lDqNY0o96+1l0GMAmoC/dZnd1P9TyG+SvDNOL92000Qq/zepE2wUBIY2OUJHzcRHh+VeUQD81OFQIPsh5X5I58B38/DdzwIC7VXC3Yq/RE8pafZB7KpmcMHPzzoEtb2fPU6NrnUI1iaoGToEb/sF44OFndhQn8q0/yaVC/7h8sbEQOU37+A2ne95w8n4WG98KgbbpuX1Freqww4hKITwU5BvmSdt8ZT3/P9E3WqvZo+XD7fidrTptGzbploOwc/sva0octEIqkQgjcxrNH8smAt7UDZ9xSHwd6O/zc/H+fSYa3Yj2DQuLKee9q6LeK/WL8HeNkSQrc0HM9J0K9ifolyuyIdMVS1fb2/aIdz26m6cTWcyfJIdahDOoWhWlCoAmACAEwBsAtECrFkAAOBAdQkAQCMwtUgRmOahMSHx9dv5BR+NcW5ODprU/XaCkgVMK8+QXdxK1EtFsMoUTxBWFbDH7jpMD1WAbmmzCdvF1YxkbfeXs+0Px6gY/agimRWm/xmp949FIEzBGQcdi1uYFKTTGDrHNGxnkthfTf/NtlGTZSm7JGthFLjZ1BricNFTzLkB9VZ9xN09+dE0/CcmEPKxMazvveRrP9Hb8fGv/9/+SLnBNUPnmcjpQYXp0CuOaVShL+5vhPShr7TpZdz66oN/fTr0UQo7TLfaz+G/MYUm103sHhbGPfUISCiBeKZQATtMxWkQ45WU2pNLdxe+gLMOtD7cTho2e5Hf3jpHlbxPW7HRdwtMuQkFClUi2YxJeTZXKcJetU6oeGXDPlz6t3eVD0s7ew4/3z3PqMEddqUZaPStdqHhIJzsRb2XQh3eBeOTKxYs1oyxetfXBwn0gpWy9BDiXkdYfUMUzpTSb3vxzptGzc1oCFq6Fg7cVrXmm17VfmuL0bJ98dz2BCBeII6KAOLQPJXqhQM6pIrw4s3q7CTJnYjKoNoiLVZ5nCBYaY/wPqSKdRY/DXLthk4w+Kb2v7tbNzAr/3SrNgeJ/Ac+Ecs2rMB5wZANctm5sFucCy+wr15hZSDJzpnUSsp1Wk6uv8yGezut5JfyE/nvka3DhnvrrY0vAQmdhk8ceVv7JDrI1C5DWxft9pZF5fBYh9ga7WnQoKxiNSzS9ePoObQf1zX0rRgFhSvM34VtcfLFjOk8+mSiZm0NPZKXMXnJcW8h9Asjmc1IBn+J33OExbnisQ7lcMsijuPtyb2JyKrrs6Nn0NuAbvl5l9323Cs1mTzjffDYldUt07O1C0ewNgdFSnG0Hf3262x2R/gJNfJDD5Udj9CuWNZbSzHL4MjkmFvnYA2pxSeRVjZvE0R5ibyhWgG+WiIhu2d93o9fuhuM3ao9Rqjvf/6W/8W7ckIuPNTBRasW7XaRKkeG5w6EVkthCJvwTWLWIPYMqwbEy380md58ujhzIfn75sMH8V3mnu8uOl94uZnSR6pzjdBuHrM0lxsC/f1e3Ik3v/B3pzS5/xB/4IfdnOu0ctMo+V2PUlDh4iHjDtOwWDK0Lk+aLR9QjM4EPFu0sW54q4RM552EqqCTPJVxRJJotP769taPURRNUD96PkbAX7CVFy4h3P0FGprwBKPRuYAqKPnAAPukNHo4Xh0P02+lMbd8lWdzQW4olFwtbliAI/1jzZtfGR4UDLRi2wkFGhZ7aNTvDUZifszx1PO37/3c9t1Sy/uXrB9aNITcUNhr0ykHkoS/+/oRzGV0OHwVQ8b634TkTlVnM7YNotzbnbWdt7nzo0MatpReSZeyryP60+1cj9GCHd8oEAolP/ss5/vDzY+31D1W1D52SsN1t92vcu0kxru4DShub7lu8tZhRIkYx8fFKBfbKgRggopRE2D1v1jGUAvMf2fwlKl6a6CzV9ADqv+XeXHC2gpC2emKyuc2vFtnGp/3l27ra9qhga8O7Gyp2FmSV7KzoiLlnb+WbeiIjzRp07PYsRYIgaTUV1e5P2it5pJLyNx2QeyGWnVMlPjR/jOti6ZStGVZTzvwgoXjWfHMi7x69oYusUKKYO3yrtyyKj5UDPFLFjb+mffqhysPI4hMoVAh88+71XT10PEsDszyQkIl8l0XVAZ11T+EYZM6xpmSSZb9L5piCQ8jYgWX3Xrxl8wTcBPjNRh+jdEEn8hMPdjKVnBFn7A7yjvYzsSsU1xKBYV7fdFWDvpGYkSmWJPHcGPww+nCnQezeiEaq9304fncrF4pH6fqC9DF9HOZobPpwbdCnQ6dku/GRlt/tJoJcAxf0TyXL2jVB5iD3Xt30ESeIWZdPQQH0A+Iyi0C+8s5BLwym5yJE6wGwYBb6zMxT2LFU0hTVoxNqJJbIQFR9NAoMaqK0qKQPSo65siSQizR7IkJNvR0P4bra/Q93imFWEJerke1c9b6pA5UNEWJaPNaIdaQ0rT4gMf2HKJWaXLLAl29/DuXboAXL5xH6pULyuRSNX2ZRnbtYxpoEAsYRmmPpDR55DlzmEiygQQ9wPucYCIbucB7CHwq+B5/jS+ORwQAgEaJZdiGY/PkzSg1wifCSQdO4maZbeENek+2TiYw5Wew5DUBbpRQmuw4kxaCXTXBTpnSNrGAwgsSHl0IhWkPGMZa2FkhYMu+vRRyygTl/j8zBzLZF8Tm/QuIXXrBwaMy7IVqdmGUcZRkQyBP0P2pzHnG3CYtV3RJn78+MsJbGlaKOH1QGX2eO7nMkJoysMBCCnIDMi2GbgblFpmdR6oNZno0IdAMASN/2hSUai84Vbp4spwbJ3+8RYrJ6jmWKVtkMMdDadkEzB5ThlraVOQW5JOfPxgoUrPfI/R67SS84+0WUCW1Sez2hGO45h3KIssyGV/20CK0zR6Ol1RGTmcchZmtc2QPSfWJEQe0OjrONCOcqqaiHu5wqb9KVq5FEMiwNIOswKA8l7ySFbJ1jbU7m4agn40LS0FnAmFGjQVMdTyxFp2sbawT5cKVOlrM0qPgHJkseaRiinNjkgl5qbjYQMseqkoy9tXEdolyZY4r80IFNvkpP+6MIQ5e9FBO+drzLD6OWbaODV6W3c026dgNUSOvI/FAJSqr/ee8TuU7UZUEXIuFo7pBdWF3RAsxJNpIQKZx+Wk18pRPsgNJkeMTkCc0JBJRZ4WbOKFGTlF7RqQyrfyzUgqCyi0h/jmhpChCRdvmsOnRkYiG7L2+2nBiZAOfLPg7wZ9lLv7+M21o3USAuERhGHNh6ppvRcPnMeKCdMyAKOJ4qjv8nMgW7XUip46ltNW/ORRplpNS2Y8yUvXWKqMOntamVjeEOsREgNC7DhR34U3rCS5Bqajwp2riI+OtgSWWXna61qfI6RMwog/TOiHajYlaKWhvEwc2tYSOP3JJkFBHqggjRdgipbKOjDozp6hr0kUdn+HsB9ekZ7Vr8vfSjmvSjdrNo/z6c8nzNXINgCdqoyxALWHBEpZIRhFLMqoiUTON1ZkB16RntWvSA/qMmCUM9yEM+na7va+tVgq6YeKauOrjFxJfABCAfPRo9CfhVcH/Tjb/HQC+WovsBwDg69+eJf6JlNVFEQLIxQAAgahu/4F4Nyx8HSDDB0qqMyh9CbBhHK5TZUkMzPpTxXL03lE1ypoPXddiIbAEK2HQxlqzFPSi+J++FQ2VBBVyuUioYHTljP+dJ8DECZmuykAAQAHD+iAQwHZBKmp3AVzwwmYM2eSpMUzFdAy3xY5zCjXGkljEsn4hwH4Ig14+E2YNGBEQJROME46jOmziodym+KEmRES5Y9YHLbfEyq7ZSHLTgTbSoZ+dPfuIIKJf1AvARgA29ITb650bJPHiloTMibjHdnKZBFphmeXWK0m9FBxJ35SmtJ2PD5haR116gjqMmK7Po+GG05s1HLZ0Dha6OCwNsBGqltkSj5/5ChOlVAXgjLyrapmxtsQ3hHd33/orDORqCa6LWaeWcEdJU9QTwj0J52nwTOTOPVme9SiM2NBZXbpIi2/bjZ1tO3Et1Cbd2bEHz2KFWtu1D2zJ5xkFEyo7QBbYacOzMi7vyFTgnnwHCCzVFTl3FbiHiRJLy7lbzNNs9sgc/KjdZN5WEbpXe5t9n/0aaeth/2vKrTtoL8zcC1QtP4DIzDIQxwA=";
  
  string private constant IBMPlexMonoSubsetUnicodeRange = "U+20,U+2d,U+30-39,U+61-66,U+6d,U+6f,U+72,U+74,U+78";
  
  string private constant IBMPlexMonoSubset = "data:font/woff2;base64,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";
}