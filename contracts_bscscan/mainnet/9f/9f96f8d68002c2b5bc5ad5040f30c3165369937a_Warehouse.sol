/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.10;

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}


contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }


  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}




contract Warehouse is Ownable {

 event Response(bool success, bytes data);
 
    function transferforERC20Tokens(address _addr, address recipient, uint256 amount) public onlyOwner{
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("transfer(address,uint256)",recipient,amount)
        );

        emit Response(success, data);
    }
    
    /* Requires attention to use. If you use this approve function for an address,
       the approved address can use the transferFrom function to move the token from the contract using this contract as sender. */
    function approveforERC20Tokens(address _addr, address spender, uint256 amount) public onlyOwner{
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("approve(address,uint256)",spender,amount)
        );

        emit Response(success, data);
    }

    // If an EOA has previously approved the token to this Contract, you can use the transferFrom function as a sender for the EOA that approved this Contract.
    function transferFromforERC20Tokens(address _addr, address sender, address recipient, uint256 amount) public onlyOwner {
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)",sender,recipient,amount)
        );

        emit Response(success, data);
    }

        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
    function sendViaCall(address payable _to) public payable onlyOwner{
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        
        emit Response(sent, data);
    }

        // This function is no longer recommended for sending Ether.
    function sendViaTransfer(address payable _to) public payable onlyOwner{

        _to.transfer(msg.value);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}
    
    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}