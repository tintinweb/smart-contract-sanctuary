pragma solidity ^0.4.15;

// File: contracts/minter-service/IMintableToken.sol

contract IMintableToken {
    function mint(address _to, uint256 _amount);
}

// File: contracts/minter-service/IICOInfo.sol

contract IICOInfo {
  function estimate(uint256 _wei) public constant returns (uint tokens);
  function purchasedTokenBalanceOf(address addr) public constant returns (uint256 tokens);
  function isSaleActive() public constant returns (bool active);
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

// File: contracts/minter-service/ReenterableMinter.sol

contract ReenterableMinter is Ownable {
    event MintSuccess(bytes32 indexed mint_id);

    function ReenterableMinter(IMintableToken token){
        m_token = token;
    }

    function mint(bytes32 mint_id, address to, uint256 amount) onlyOwner {
        // Not reverting because there will be no way to distinguish this revert from other transaction failures.
        if (!m_processed_mint_id[mint_id]) {
            m_token.mint(to, amount);
            m_processed_mint_id[mint_id] = true;
        }
        MintSuccess(mint_id);
    }

    IMintableToken public m_token;
    mapping(bytes32 => bool) public m_processed_mint_id;
}