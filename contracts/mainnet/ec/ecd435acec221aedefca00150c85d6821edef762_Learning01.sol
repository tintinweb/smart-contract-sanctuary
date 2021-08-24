/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

pragma solidity =0.8.4;

interface IPOWNFTPartial{
    function mine(uint nonce) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract Learning01 {
    
    IPOWNFTPartial mainContract = IPOWNFTPartial(0x9Abb7BdDc43FA67c76a62d8C016513827f59bE1b);
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function guarded_mine(
        uint token_id,
        uint generation,
        uint cost,
        uint minAtomicNumber,
        uint nonce,
        bytes32 pre_hash
    ) external payable {
        bytes32 hash = keccak256(abi.encodePacked(pre_hash, block.timestamp));
        uint atomicNumber = calculateAtomicNumber(token_id, hash, generation);
        if(atomicNumber>minAtomicNumber) { 
            mainContract.mine{value: cost}(nonce);
            mainContract.transferFrom(address(this), msg.sender, token_id);
        }
    }
    
    function withdraw(address payable to) external {
        require(msg.sender == owner);
        to.transfer(address(this).balance);
    }

    /// @notice Round up to calculate "ceil".
    /// @dev Because the metadata uses Javascript's Math.ceil
    /// @param a Number to round
    /// @param m Round up to the nearest 'm'
    /// @return Rounded up 'a'
    function ceil(uint a, uint m) internal pure returns (uint ) {
        return ((a + m - 1) / m) * m;
    }

    /// @notice Calculate atomic number for a given tokenId and token hash
    /// @dev The reason it needs both is that atomic number is partially based on tokenId.
    /// @param _tokenId The tokenId of the Atom
    /// @param _hash Hash of Atom
    /// @return Atomic number of the given Atom
    function calculateAtomicNumber(uint _tokenId, bytes32 _hash, uint generation) private pure returns(uint){
        if(_tokenId == 1) return 0;

        bytes32 divisor = 0x0000000001000000000000000000000000000000000000000000000000000000;
        uint salt = uint(_hash)/uint(divisor);

        uint max;
        if(generation >= 13){
            max = 118;
        }else if(generation >= 11){
            max = 86;
        }else if(generation >= 9){
            max = 54;
        }else if(generation >= 7){
            max = 36;
        }else if(generation >= 5){
            max = 18;
        }else if(generation >= 3){
            max = 10;
        }else if(generation >= 1){
            max = 2;
        }

        uint gg;
        if(generation >= 8){
            gg = 2;
        }else{
            gg = 1;
        }


        uint decimal = 10000000000000000;
        uint divisor2 = uint(0xFFFFFFFFFF);


        uint unrounded = max * decimal * (salt ** gg) / (divisor2 ** gg);
        uint rounded = ceil(
            unrounded,
            decimal
        );
        return rounded/decimal;
    }
    
}