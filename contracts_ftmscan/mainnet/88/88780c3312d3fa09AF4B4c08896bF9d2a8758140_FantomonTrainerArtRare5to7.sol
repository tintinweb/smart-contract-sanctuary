/**
 *Submitted for verification at FtmScan.com on 2022-01-10
*/

/*
by
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
with help from
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░
*/
// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File contracts/IFantomonTrainerArt.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IFantomonTrainerArt {
    function getArt(uint256 _face) external view returns (string memory);
}


// File contracts/FantomonTrainerArtEpic5to7.sol


contract FantomonTrainerArtRare5to7 is IFantomonTrainerArt {
    string private PREFIX = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHwAAADhCAMAAAA9OCERAAAAAXNSR0IArs4c6QAAA';
    string[3] private PNGS = [
        // Rare5
        "GNQTFRFAAAAAAAAwebmsu///8N32t3DcIFV/7pq/7Bk+dWk6ptf/6Zhso9c/8yK6atf/8R2//bfoXpxyJNe/92iIxoOGBIREg8WCwsbBQgg/xlq/wCZ//fw956C/5WCMQUUxqx+/+YAg+VusAAAACF0Uk5TAP//////////////////////////////////////////RvROpAAABBZJREFUeJzt2/1u4yAMAPD5jz5AlRQJCRTe/ykPbCCQpDdgBDrN1q7r0u1+NR8OIduXmBhfk/HnpCAcP8YGmZj5aBr5PfMJbR7w8bbVGWf87+Ez5/nsCjecTircaNujlLl4DA4Qn4GPppFnnHHGGWec8Q/AAWMGbtkF46d8Aw7bsi1LD74Sh5j1zrd3QB2ewZuN8KTtDVThkLA+/Nf2lYY3UIMn9nJ+Sm9iKl6lV+CwRSMFl0NU8OW4s+HswfnJTfhFwMWhUr4YPyHGhZWoE/KXC/UafDvS9piBy/zL9FIc8r52Mv1zJQ+2tmFXhlNNzXEfDoatTS/HU8Ak4QqbewlHQJ1eh6/+/w2uo6nMAtinGd8Lp0aPmUOStMbEIRxaq/Ri3MTMDQRaKwwNaTd0xp29mph5GOna20pj+rEnwri4DYeYNul78hBT/14vxU2OqyxS3IR6A9+3exdc6azbizu9DN824/QTrq/08hHXgNupdsz8ZnwrwwGSOtMFf0C6WiRc6wNOOnTPfDLuK/j7Zk87/QbcBH11tf1CBxPqbl/84XGg4oH6ecy5sicSvtOJJeCkr9jwV7jtedIXcwMe+90mqfR7HJPviZuIu8wuut2d3NUNuP0+h/tBF84gMec43V4qqfH9cKtv+4g3eeZh0r/uwl2loUGHq/Uw4AB7X3taqX3CdVtAet34dcQ+1IEenE7ZxyVWv6Wzx7cDnY92m3lo9nXteNEQ9fc2jTcVTm4ldj2en1H0/qjdu8J1ZP+rVPxmXDhmvMbwT1Tl1lTtPpwrJGfdf67dkGrDjzrR1ZthLbjCBj7yd+/D4Q+Eq4VdxwMtm5D1e6/XM61pA7Rl4zdv73b71+FeByFErOhNdtudhnSkU20biD/SdYSd4EMz33WtcMaPxR+4hHBlbXif009Ge3SzP+gUF9p+PL5P9ml42/nsp7gIaav6E3kn3M/0ceU1wyn/tvt6rUVGCFo77XjDfb222u53IHW8SrNfSynvvKkXf8YyfqRR9t6u1lvO5w7xq0ZcTGFDyAa9YRklfV1X2PS+t18Oxo87cSTobKJ3m3pc4qe7cEA61vQwyMmW9HDbFctMPCDIw05nuCyf7zXX50JG4xASwnFZo1dsiwgZcZm6MW35qpzv5RtCghLzE/oykunedWciuu/xpNYU5l66CQhxML2Bs9cKB33E//cbv3E4h+7NkkzHQHboO1qU4ZTN2TvxMnZ6Cf4pv+U9IT7ibxqmNvvwP6nI8bE2NjrjjDPOOOOMM84444wzzjjjjDPOOOOMM84444wzzjjjjDNeg0+9ozjzXuqEiPiUmIs/OfMZOGc+BefMp+Cc+RT872YunowzzjjjjDPOOOO/FucF5AycM5+C/919OMYZn4BPCsTnxVT8H9K/lXXZ5ituAAAAAElFTkSuQmCC",
        // Rare6
        "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",
        // Rare7
        "FpQTFRFAAAAAAAAwebmsu///8N32t3DcIFV/7pq/7Bk+dWk6ptf/6Zhso9c/8yK6atf/8R2//bfoXpxyJNe/92iIxoOGBIREg8WCwsbBQggIxoO/zwA5vL/p7C5eR0BtYIiyQAAAB50Uk5TAP///////////////////////////////9r//////Rm6QwAABKNJREFUeJzt221vmzAQB/D+X4xMvCAKUpGCxPf/mrPPT2cTgk0w7tTz1ixNm/248/kwSfs1NRxfjfFHo2Fw+nvtMCZFfjVNfIi8Qc4dfr2tdMEF/314y3XeusNdTrMOd7VtURP59Ofigeln4FfTxAsuuOCCCy644P4/sON6XKE3Gvf7Ef0T3Mh3Jd9vf+8Hgj+Mm6AHNsqDP4gTPaSjVD+Gv6S1XsYfwhV9f2WXBn8EhyqxDbtMP4Cn9gMP+ijXy/FpM+XFejGOlZ1EPtyy9VJ8bX8QeiGOFyssjTxfPwE3o6eM18S37WjkNtrPcPOp6XbsS/0l+ObI04twbOAYhlHf3qriKxt08z2MGtc6LsMNrYbFAf9gbRxWXmb0o9IxL8ZHrl4450nkWNSYDd4rXA/kh/4JrrSZBuEj6L46mFqRI7LtAHTWR4QHKuFO75k90JT72Omh03G6OKCa6/sePGxd7GqtMz2rwxbggLo0SHGT8YFwraMk8SU42TEOG7QdPvWVcD3t3A7swFOfNeuF+E396XuHg4Xt7lr9fHzUHe3Ww+LcHuDwgfTzcT2TIFvjuqVz3M+AOsIKOG2W4PEo4yPC9FfAtd7bWu8RbL/OwsFUwEm/2ZUW5TwZY+ZLFeW47rAK35SpACr0dqX3Std4GmuCV9hM2EaThqkGJXr0x1Rl92pOLvEFE2gDYbYRruIr4XR+ScLWS97c2KxUulyip9wjW+9mTEedaRNXFw96b+K2Nqw+VrtENk+iZmdeeVysPVPiTfKr4tTnve2T7lNQGwcV+OxFt32iDWzNOXc4B90hmNir4mTziMMuuiTxh/HFpxsrfanTXpmdZNplv2TWy18KC1XOZzvGM2e99MSCpxox7hZ5VH41LpeU3HVY48kkZOpF2ygFd8b26ywt9HBAJ28gmY1lpa9W3n7w2bjJeOfeTFpCuWONm5LfrflcXIUd2XiN+xnPer+rAFdjCvZ7/NQ5B+W8Y3Y4nfloeeRZejZOtq30xZ7QOG66jI88Sy+LPEx6yHFYYvD3v+n+6bjR+QTzfQxb6zkbmlx8cnjnw4776RynPWs7lYcDRuWxv+qt4V9Q4s/AVU9XbuhwrMbnKGJ+qsmY9Rxc2YrsXNz6ZmYl5+ovqUHsZz4DB2xv656dzzyzwD7jTWbebXL7OFtlT8DdZxSPO6oEUF/4BA+LjKK3nS4KmCc9mgPTlI7jPlZf6LSViaKMcVbxeprUNx/FXai22iyPuMJX5WYnRePqKdv6Hs4726rNJKsr2tOZ76fnbOrv8TjpMe4KbnuZ+wPe0nfwYJuNjDuxzph5g0eUcue7hdltzftbPLa9bouanVB5zwtn1W7yz35d8x5/8RO/SdJJf9oO40LkLw4E3H4tVOorHdMbHAyn2dMN/tkhPqWwKl/V3x7+U37Ku8H4Eb/T0DTtl/9KRYxfa1PSBRdccMEFF1xwwQUXXHDBBRdccMEFF1xwwQUXXHDBBRdc8BK86TuKLd9LbTA83mS0xR8SeQtcIm+CS+RNcIm8Cf57I58eggsuuOCCCy644P8tLhvIFrhE3gT/va/DCS54A7zRILzdaIr/A/oZXRlOPROzAAAAAElFTkSuQmCC"
    ];
    function getArt(uint256 _face) external view returns (string memory) {
        return string(abi.encodePacked(PREFIX, PNGS[_face]));
    }
}