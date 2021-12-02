/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

contract Reader{
    event console_log(string resp);
    mapping(uint => bytes) test_traits;
    function hex_map(bytes1 item) public returns(string memory){
        bytes memory _map = "abcdefghijklmnopqrstuvwxyzABCDEFGHI";
        string[35] memory _imap = ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34"]; //cheaper than converting
        for(uint j=0;j < _map.length;++j){
            if(item == _map[j]){
                return _imap[j];
            }
        }
        revert();
    }
    function svg_unpack(bytes memory _trait) public returns(string memory){
        string memory css  = string(abi.encodePacked(_trait[1],_trait[2],_trait[3]));
        string memory svg = css;
        uint j = 4;
        while(j < _trait.length -2){
           svg = string(abi.encodePacked(svg, abi.encodePacked(
               "<rect class='s",
                    css,
                    "' x='",
                    hex_map(_trait[j]),
                    "' y='",
                    hex_map(_trait[j+1]),
                    "'/>"
            )));

            if(_trait[j+2] == 0x2e){
                css = string(abi.encodePacked(_trait[j+3],_trait[j+4],_trait[j+5]));
                j += 4;
            }
            j += 2;
        }
        return svg;
    }

    function reader(uint index) public{
        svg_unpack(test_traits[index]);
    }

    function add_trait(uint index, string memory _trait) public{
        test_traits[index] = bytes(_trait);
    }
}