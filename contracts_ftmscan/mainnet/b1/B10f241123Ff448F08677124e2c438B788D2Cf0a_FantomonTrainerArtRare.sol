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


// File contracts/FantomonTrainerArtRare.sol

contract FantomonTrainerArtRare is IFantomonTrainerArt {
    IFantomonTrainerArt five2seven_;

    constructor(address _five2seven) {
        five2seven_ = IFantomonTrainerArt(_five2seven);
    }

    string private PREFIX = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHwAAADhCAMAAAA9OCERAAAAAXNSR0IArs4c6QAAA';
    string[7] private PNGS = [
        // Rare1
        "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",
        // Rare2
        "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",
        // Rare3
        "GBQTFRFAAAAAAAAwebmsu///8N32t3DcIFV/7pq/7Bk+dWk6ptf/6Zhso9c/8yK6atf/8R2//bfoXpxyJNe/92iIxoOGBIREg8WCwsbBQggbXnyKUz/EiJxlQoA/9b/qo+q8svyKdYd/QAAACB0Uk5TAP////////////////////////////////////////+Smq12AAAGBUlEQVR4nO3bC2/jKBAA4B3JFeKkPCo3+KSVyf//l8fwHsCJiVO7pw63zW6y13zMABOwu3/Uge3PwfjnQc3h9te+zZk28r1py6fID8h5wPe3jc44478PP3KdH13hdqezCre37VEXufrYuYH6GfjetOUZZ5zxX41Du+2BA8y+adrexy/ikY5+6kcW/qZMrIm8aMk3D7Qrb8Of8QbVgPl4fSQez/Yl3XcA3GD4TPR34MlSg8XojWnZbEZ2+w9xu7KWg494Wg99ehv3K/p+vz/TySzQc5/ewIPr2mNdVy/06DVOaM8/Dv9lvcRLOfYA3xiyBOfjTp+v1ym+IIfWxIoXemYdwR/bBTdXvu7Vc7xh2/cs8Cr0tNT8k7XrPcMrW7doM/I1Tnu0Wk94aWtiZzo07GBCl57htY2PzfFu23Nak+uGPY8cqG1/c8+gsHXxfI6V1vvrQs/H3CCBznOQl5j0UTYHyrfUJaeviZ3OdoAyfnzbzC6U2ITI+gRrE1+VV++HBxvqHEZSQzbVdb6rFADl8nuul/h0j8n3UJ7zpi2xDaLAb/24dW/5jIe8cmZJ1x52ttGhLHov4IrYJJka0sjqKQa9hD/XH32w1HbILVR2wFOV68fJCitsHeY02LgltX1S/KZuXZWjn2phjbsZr0kmNQxSCoh7RVk0Nx2UmuPi6MItiKVtirG7d/l3njCSwcdn2pTbtMzYMvsC7oc5JJ/snRA3zS8/GnPSZ19j8aELn8DO7zjrSjvhRcoJ7s4PNgcduHtbSLOO4maQA17Ffb1eY+K1ksKPVxdui1JcbXDPbaUU2mOFg7peA+76LwTOvk4cYPpI21fIcQCkpcOpPU2TUgSXFtedE869EAMPuJpdynE1G7yIe7pPysJnyCYjduQ1HEjWdRhuh1P7qqYprPkct3nfEnmaaxdv23cl9lWlcuPsyfxhtD3p/0jNKmyyc9y3Eb/g6uUx4mBT4JZfN15Pdh94gftEZ0/OWQmAF/F7jrvluoifaFccPmJKsGNP7eZmIuL+83NYwmWFA+L4n+zcvVL8PsfI19mS1p834Np+lFo727CtsDfhk8G/PC5MScf6N13D7Ja3uheb8SxwCBebNJYYpCcsZfG9WzipAdtwHfBB2rjv+Q5iGXf7q97jUoX7hgcCuH4oRQKr8ZAWX9w34RB4O9GwkMpHOJ2MvedzikPCtatX5RaiwvFxGMR6ewm3O5qE162xe5V2Ay1WpryFu92z/fYYemNdLTTExforsAu4e/Yo9CW85+JveVzS2/Ch68JzgZsTg76Hg07C1+om8g67Kq/6nk54YV+0XjeRb8J1OuEhPrkzzDp8EH2356rNRHa0tWsdXIVr68WrnYE39nDZxs9fkxFYZcZarno0wLbIyY0yf+cKjyBSVSWtMeIb025eyf/WTTajj7IOvbKH8zvusWS4u8om5Cq88/bS81tb5sws5IrQMfC3Ro66+VI2dKEe2+Ysed465jWOjxL9xpRP9td56Cxwz/HYCRx5GBd4jFucN6/z5f/THNKhtd7deJsmvg8P39AKXgzK+d+Mm+lX+ULcMPDLpWMj8Rrur4orNYY+CBf2xbTvx10HRuPd7A/VuYxb/LIT7qaYEENsLvQN91L78NBMJ74E6nInHAjuUnCRXfp7cDP68oz4YM6vKr/38rAnb4vc4O5i3Q3+mr/8axo868UGXGa6RDkeljyetXYXXsQBwlVJEXkb+T9SRDv+hi+o2IsteAzClXRcXx63AyBo3H4CKJKFV3HIbKL7DIgi5ZCjEPL/Ek5mUPw4kwY/u7CtDRRvTL5wMOj4iV/6/SNuL+yX74No2DRg82kAp6ibNbkeLzp/E6aqCbvBwj4MuNOxDtWz3mIPTyc4nUZwu7Of8lPeB7Qf8W8aDk377v+kguL72jbpjDPOOOOMM84444wzzjjjjDPOOOOMM84444wzzjjjjDPOeA9+6B3FI++lHtAifkg7Fv/kyI/AOfJDcI78EJwjPwT/vZGrT8YZZ5xxxhlnnPH/Lc4byCNwjvwQ/Pdeh2Oc8QPwg5rFj2uH4v8BBvHC8Camv4cAAAAASUVORK5CYII=",
        // Rare4
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