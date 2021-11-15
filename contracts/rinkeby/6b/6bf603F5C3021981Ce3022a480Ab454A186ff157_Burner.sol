//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;


contract Owned {
        address public owner;      

        constructor() {
            owner = msg.sender;
        }

        modifier onlyOwner {
            assert(msg.sender == owner);
            _;
        }
        
        /* This function is used to transfer adminship to new owner
         * @param  _newOwner - address of new admin or owner        
         */

        function transferOwnership(address _newOwner) onlyOwner public {
            assert(_newOwner != address(0)); 
            owner = _newOwner;
        }          
}

interface ERC20 {
    function transferOwnership(address _newOwner) external;
    
    function transferFrom(
         address _from,
         address _to,
         uint256 _amount
     ) external returns (bool success);
    
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function burn(uint256 _value) external;
    
    function transfer(address recipient, uint256 amount) external returns (bool);

}


contract Burner is Owned {
    ERC20 oldToken;
    
    function returnTokenOwnership(address _newOwner) public onlyOwner {
        oldToken.transferOwnership(_newOwner);
    }
    
    constructor(address _oldToken) {
        oldToken = ERC20(_oldToken);
    }
    
    function burn(uint256 _val) public{
        oldToken.burn(_val);
    }
}

