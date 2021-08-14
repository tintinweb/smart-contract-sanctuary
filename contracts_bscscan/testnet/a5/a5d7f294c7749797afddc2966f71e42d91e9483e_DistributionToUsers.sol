/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

pragma solidity 0.8.0;
// SPDX-License-Identifier: UNLICENSED
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

 

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface Token {
 
    function transferFrom(address, address, uint) external returns (bool);

    function transfer(address, uint) external returns (bool);
}
 

 
contract DistributionToUsers   is Ownable {
     
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    address public token = 0x903fCaf1A49B29678C15B43bc9F852232BfA7dF1 ; 
 
 

    function distribute(
        address[] memory users,
        uint256[] memory value
    ) public onlyOwner returns (bool success) {
        
          for(uint i = 0; i < users.length; i++) {
                address _user = users[i];
                uint256 _deposit = value[i];
                 Token(token).transfer(_user, _deposit);
                emit Transfer(address(this), _user, _deposit);

            }

        return true;
    }


      function transferAnyBEP20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {        
        Token(_tokenAddr).transfer(_to, _amount);
    }

}