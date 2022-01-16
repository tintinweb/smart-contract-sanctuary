// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Burnable.sol";
import "./Counters.sol";
import "./IERC20.sol";
import "./ERC1155Supply.sol";

contract Gether is ERC1155, Ownable, Pausable, ERC1155Burnable, ERC1155Supply {


    // start additional code
    address internal tokenAddress;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // end additional code

    // constructor was modified
    constructor(address _tokenAdd) ERC1155("") {
        tokenAddress = _tokenAdd;
    }

   // end modified

    // start additional code

    function setTokenAddress(address _tokenAdd) public onlyOwner {
        tokenAddress = _tokenAdd;
    }

    function getTokenAddress() public view returns (address _tokenAdd) {

        _tokenAdd = tokenAddress;

        return _tokenAdd;
    }

    // end additional code

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //start modified code

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
    {
        
        deposit(amount);

        _mint(account, id, amount, data);
    }

    //end modified code

    //start additional code

    function burnAndWithdraw(uint256 id, uint256 amount) public 
    {

        _burn(msg.sender, id , amount);

        withdraw(payable(msg.sender), amount);

    }

    function mintIncremental(address _recipient, uint256 amount, bytes memory data)
        public
    {

        deposit(amount);

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(_recipient, newTokenId, amount, data);
    }


    function deposit(uint256 amount) 
        public 
        onlyOwner
    {

        // Check if transfer passes
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        require(checkSuccess(), "ImgToken#deposit: TRANSFER_FAILED");

    }

    /**
    * @dev Withdraw tokens in this contract to receive the original ERC20s 
    * @param _to      The address where the withdrawn tokens will go to
    * @param _value   The amount of tokens to withdraw
    */

    function withdraw(
        address payable _to, 
        uint256 _value)
        public 
        onlyOwner
    {
      IERC20(tokenAddress).transfer(_to, _value);
      require(checkSuccess(), "ImgToken#withdraw: TRANSFER_FAILED");
    }

    //end additional code
    
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }


    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    //start additional code

      /**
    * Checks the return value of the previous function up to 32 bytes. Returns true if the previous
    * function returned 0 bytes or 32 bytes that are not all-zero.
    * Code taken from: https://github.com/dydxprotocol/solo/blob/10baf8e4c3fb9db4d0919043d3e6fdd6ba834046/contracts/protocol/lib/Token.sol
    */
  function checkSuccess()
    private pure
    returns (bool)
  {
    uint256 returnValue = 0;

    /* solium-disable-next-line security/no-inline-assembly */
    assembly {
      // check number of bytes returned from last function call
      switch returndatasize()

        // no bytes returned: assume success
        case 0x0 {
          returnValue := 1
        }

        // 32 bytes returned: check if non-zero
        case 0x20 {
          // copy 32 bytes into scratch space
          returndatacopy(0x0, 0x0, 0x20)

          // load those bytes into returnValue
          returnValue := mload(0x0)
        }

        // not sure what was returned: dont mark as success
        default { }
      
    }

    return returnValue != 0;
  }

  //end additional code
}