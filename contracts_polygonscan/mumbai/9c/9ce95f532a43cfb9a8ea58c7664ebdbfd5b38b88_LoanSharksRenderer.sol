/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

//SPDX-License-Identifier: MIT Lisense
/// @author Alpine
pragma solidity ^0.8.0;

/**
 * @dev External contract to handle rendering of encoded Loan Shark traits into a complete SVG NFT.
 */
contract LoanSharksRenderer{
    //DATA Struct
    struct SharkTrait {
        string traitClass;
        string traitName;
        uint256 pixelCount;
        bytes traitBytes;
    }

    //Trait Map
    //0 => Background
    //1 => Species
    //2 => Body
    //3 => Hat
    //4 => Eyes
    //5 => Mouth
    mapping(uint256 => SharkTrait[]) internal traits;

    //Utility lists
    bytes _map = "abcdefghijklmnopqrstuvwxyzABCDEFGHI";
    string[35] _imap = ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34"]; //cheaper than converting

    //Deployer address
    address _owner;

    constructor(){ 
        _owner = msg.sender;
    }

    /**
     * @dev Utility function that maps string letters to string numbers
     */
    function hex_map(bytes1 item) public view returns(string memory){
        for(uint j=0;j < _map.length;++j){
            if(item == _map[j]){
                return _imap[j];
            }
        }
        revert();
    }

    /**
     * @dev Returns the SVG of a Loan Shark Trait
     */
    function svg_unpack(bytes memory _trait, uint _trait_len) public view returns(bytes memory){
        bytes memory css  = (abi.encodePacked(_trait[1],_trait[2],_trait[3]));
        bytes memory svg = "";
        uint j = 4;
        while(j < _trait_len - 2){
           svg = (abi.encodePacked(svg, abi.encodePacked(
               "<rect class='s",
                    css,
                    "' x='",
                    hex_map(_trait[j]),
                    "' y='",
                    hex_map(_trait[j+1]),
                    "'/>"
            )));
            if(_trait[j+2] == 0x2e){
                //Hexadecimal ".": the delimiter for a new css style.
                css = (abi.encodePacked(_trait[j+3],_trait[j+4],_trait[j+5]));
                j += 4;
            }
            j += 2;
        }
        
        return (svg);
    }


    /**
     * @dev Returns a Loan Sharks' SVG based on the 6 passed trait indexes
     */
    function get_svg(uint256[6] memory t_indexes) internal view returns(bytes memory){
        bytes memory SVG = traits[0][t_indexes[0]].traitBytes;
        for(uint i=1; i < 6; i++){
            SVG = abi.encodePacked(SVG, svg_unpack(traits[i][t_indexes[i]].traitBytes,traits[i][t_indexes[i]].pixelCount));
        }
        return SVG;
    }


    /**
     * @dev Returns the metadata for a Loan Shark given it's 6 passed trait indexes
     */
    function get_metadata(uint[6] memory t_indexes) internal view returns (bytes memory){
        bytes memory JSON = "";

        return JSON;
    }

    /**
     * @dev Public function that wraps the `get_metadata` and `get_svg` function into a base64 encoded string
     */
    function render_shark(uint256[6] memory t_indexes, string memory name, string memory description) public view returns (string memory){
        return string(get_svg(t_indexes));
    }
    
    /**
     * @dev Adds a SharkTrait array to the on chain "database", assumes an empty array
     */
    function add_traits(uint index, SharkTrait[] memory trait_list) public onlyOwner returns (bool){
        for(uint i = 0; i < trait_list.length; i++){
            traits[index].push(
                SharkTrait(
                    trait_list[i].traitClass,
                    trait_list[i].traitName,
                    trait_list[i].pixelCount,
                    trait_list[i].traitBytes
                )
            );
        }
        return true;
    }

    /**
     * @dev Clears a trait array
     */
    function clear_trait_arrays(uint index) public onlyOwner returns (bool) {
        delete traits[index];
        return true;
    }

    /**
     * @dev Modifier to only allow owner to call functions
     */
    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}
//Inspired by the excellent work done by Anonymice and Defenders of the Dogewood