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


// File contracts/FantomonTrainerArtEpic.sol

contract FantomonTrainerArtEpic is IFantomonTrainerArt {
    IFantomonTrainerArt five2seven_;

    constructor(address _five2seven) {
        five2seven_ = IFantomonTrainerArt(_five2seven);
    }

    string private PREFIX = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHwAAADhCAMAAAA9OCERAAAAAXNSR0IArs4c6QAAA';
    string[4] private PNGS = [
        // Epic1
        "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",
        // Epic2
        "IpQTFRFAAAAAAAAwebmsu///8N32t3DcIFV/7pq/7Bk+dWk6ptf/6Zhso9c/8yK6atf/8R2//bfoXpxyJNe/92iIxoOGBIREg8WCwsbBQgg4NkA/PUAycMAjLzJUi8M/0U46D8z6B8ApYr/c2Cyln3oTSwLXzcO/8GzeRAAPQkAVxCGhhnO////paWl/wAv++OZWgAAAC50Uk5TAP///////////////////////////////////////////////////////////1KX8FIAAAapSURBVHic7dvZbts6EADQjn9BopoHP8WAAY3///8qkrORIrXEC+9FSAQN6ko6muEuuX+mhuVPY/zSqEQ8/Hy2RDNE/mk68Bp5g5wz/nl70Tve8d+Ht+znrUe4j9NmhPu0TWiMfBo+XKbpzTgs5QD+FhfmpUD1Dt6FOzcnpXgHb8IzWu7gE7iDIr7w78erdqa/A6ecYywb+jm83m9SG8ReV777IQ6I+7zD2Xex5dDlRxq6dDz3E5zPR9NnSnfi/AE+ZlhnPPBGP4qDXMlfM6KgUSU3Wa7swKfVfgynlJkYQiboYj7FttRoDl7u9QCeyzNVKAFeI/92G7+vV4C/SGc4Ktm9HMdLfTbYRPOFF/327cvtRnW0DLEuH2Z/iGc3T3SS0tt1ob9uNxfuLWFDAuQuj+JJ4MgMIBTa8sKPPvbrLebDZNuZe8FjuPROnJMYl6uaniT/FKo96NdCs3OUK98N93FJKgbbVPNcLjH4UPFBj9UiR7twKYeib+CKcJOqoZoQRNXpcJMAN/prudA3NnEOG4y9g2McVYN+/b7x8OqMLgnYwnUBZK4dG5HlxhSPjWw56ftr8f3AFxuMS/WZW3wZj81FowadpkpqdguU+StwZ8F8lKHEV/BQe8JSiw9TZH2dYPBr7G8DzQnjoqeRx8QXcWuHeeSEHXqS168QcYwfJofs4DPRclq03VwY6eOxBo+6k0vhmODxLxUc7JShHaamZX/HqAMHjvSZyfgGzpkKk2OYwExfNaNZDZ+pyQ9F3EkjruAz9YU4V9pWzkmPnRDmUZs9xL6B3DESfBRdunoVR5CWGrOodlJs4LywAK52tS2uJ9TqXJZJUQcB4L783OMfy69C2ks4lBay2ziFizLQAplSktC5YVL20XS0WdYekvgqPnB1hXhQq/meF8hsmDlNCDaAAl4f4cx5s9b32pb60HvQNaXWnC74TuIgv+v2bGf4kHbktK8DP4TTmXFtWrLvps9j0va0zrm5FGbjPRw5KFQb5I+7doL00qh4ITN0jB98N5dRukvRuEE7mlllJSGhdrUiDofxOGAlOJWvcKVxtT2h7VKCpwdsLyaMDkngYFIfxleza1hHXpsAcXsZJXjYlOFqcDHlLn1xjRftg/hytscRnIGtHT9ZTXgvxNMtqLIgecC0XqXOXxE5wAR/l2LsKbCT6e9av5infdRVOGdmd9Pgy1fcMk1TWssLDtrrsna1auxJm/dtmLeKx/bn1k5bHLV7NOuMVdaTe/gBPiXaPb+XsC0jfYWPPM8ZfDiMDzZyxh8PGzrKyga0ynnipsUzr01OPRYZPD5ZmzQ/4me1IE+DcjvBh1N4GndINJixZ22Pgz6InG3kYcQ+hQ+5HUKXqQ506HHxSZHYdt2PtFnX52YHn8NldmhjmH5AkQP3swRHwtE8FDmO37OS30zo8Zx4H7jMt7rRQ98ljf1DnJbQloe74N4eXAlHGdzO44Wl1ArnAaSEy0bmybQXaK73IcH18Te8EYe7obWjAW9hdPB5PQ4RlxN0Xw/8qDYP/EU4cI3rCSg7pdngP3vBc0CHJKV2fYPwAnzVuQ2e0iZyqvl1jb8w8uy6sj17Bb6jr9+2gIn82bTX8bEQt8Ft4Jl94tVWVV/Vdzx8Vjs8FXkHDlDBk6cWRfvMS72SDjU72yo9jVfm1TqOr8TXE2vdphdi9rHkky/vCyuXLRz0+Vgp7tNvkRnex7NXji/A/RVpsbjd0ehY3sG9Bi+2+ToOBi8cdBov6pUjRX8b7qr48HK8MKtWv00goZft0zhvz7L+XjnaCT4/j1dWE9t6XEs9jQe5jG/otJB7ss7tRvGwHge6ct7PzGom6bRQ5g/qI02c3vBJHORhhMSal9qZz+LLpS9wuUT+LA615n784YD/suiDn8SEPEg5oEOpxR1+LBJsfQ70eJgvsPKH1fOfwMl+XEyw2fdnI1+/QlxFn8eBbZ/fB6zhQzqU9B3cJzjYXLliA6vCn9e3n7d7wdga9CPikOPnMr/1gideHzivsVnv4FuxQ65vvFeLYVPAHDfpD2Bc+T2dx8gCnn/jlzIOuQ3csSQtGb6lD/YrwPWvG1tb6xv8D40q0uxO4aYYvPG3vBuU/8T/aWia9o//l4oU/6wdkt7xjne84x3veMc73vGOd7zjHe94xzve8Y53vOMd73jHO97xjnf8DN70jWLLd6kNiuBNSlv80iNvgffIm+A98iZ4j7wJ/nsjny4d73jHO97xjne84/9bvC8gW+A98ib4730O1/GON8AblYC3K03xf2ClJGhFflhRAAAAAElFTkSuQmCC",
        // Epic3
        "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",
        // Epic4
        "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"
    ];
    function getArt(uint256 _face) external view returns (string memory) {
        if (_face < 4) {
            return string(abi.encodePacked(PREFIX, PNGS[_face]));
        } else {
            return five2seven_.getArt(_face-4);
        }
    }
}