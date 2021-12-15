pragma solidity ^0.8.10;

contract RenderSVG {
    constructor() {}

    function renderToken(
        string memory c1,
        string memory c2,
        string memory c3,
        string memory c4,
        string memory c5
    ) public pure returns (string memory) {
        string memory render = string(
            abi.encodePacked(
                c1,
                '" points="255.9231,212.32 127.9611,0 125.1661,9.5 125.1661,285.168 127.9611,287.958 " /><polygon fill="#',
                c2,
                '" points="0,212.32 127.962,287.959 127.962,154.158 127.962,0 " /><polygon fill="#',
                c3,
                '" points="255.9991,236.5866 127.9611,312.1866 126.3861,314.1066 126.3861,412.3056 127.9611,416.9066 " /> <polygon fill="#',
                c2,
                '" points="127.962,416.9052 127.962,312.1852 0,236.5852 " /><polygon fill="#',
                c4,
                '" points="127.9611,287.9577 255.9211,212.3207 127.9611,154.1587 " /><polygon fill="#',
                c5
            )
        );

        return render;
    }

    function generateSVGofTokenById(
        string memory preEvent1,
        string memory rsca,
        string memory id,
        string memory telegram
    ) public pure returns (string memory) {
        string memory svg = string(
            abi.encodePacked(
                '<svg width="606" height="334" xmlns="http://www.w3.org/2000/svg"><rect style="fill:#fff;stroke:black;stroke-width:3;" width="602" height="331" x="1.5" y="1.5" ry="10" /><g transform="matrix(0.72064248,0,0,0.72064248,17.906491,14.009434)"><polygon fill="#',
                rsca,
                '" points="0.0009,212.3208 127.9609,287.9578 127.9609,154.1588 " /></g><text style="font-size:40px;line-height:1.25;fill:#000000;" x="241" y="143.01178" >Conference</text> <text style="font-size:20px;line-height:1.25;fill:#000000;" x="241" y="182">',
                preEvent1,
                '</text><text style="font-size:40px;line-height:1.25;fill:#000000;" x="241" y="87">#',
                id,
                '</text> <text style="font-size:40px;line-height:1.25;fill:#000000;" x="241" y="290">@',
                telegram,
                '</text> <text style="font-size:40px;line-height:1.25;fill:#000000;" x="241" y="39">ETHDubai Ticket</text></svg>'
            )
        );

        return svg;
    }
}