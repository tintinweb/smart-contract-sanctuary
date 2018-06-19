pragma solidity ^0.4.8;

// an interface to ERC20 contracts
// only adds the signatures for the methods we need for withdrawals
contract ERC20 {
  function balanceOf(address _owner) public constant returns (uint balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
}

contract Capsule {
    // store the eventual recipient of the capsule
    // who will be allowed to withdraw when the time comes
    address public recipient;
    // the date of the eventual excavation store in seconds from epoch
    uint public excavation;
    // your friends at ETHCapsule, thanks for your support!
    address public company = 0x0828be80e6A821D6bf6300bEa7f61d1c4e39496F;
    // percentage of funds shared at withdrawal
    uint public percent = 2;

    // event for capsule creation with pertinent details
    event CapsuleCreated(
        uint _excavation,
        address _recipient
    );

    // constructor for the capsule
    // must put in an eventual excavation date and the recipient address
    // also allows sending ETH as well as listing new tokens
    function Capsule(uint _excavation, address _recipient) payable public {
      require(_excavation < (block.timestamp + 100 years));
      recipient = _recipient;
      excavation = _excavation;
      CapsuleCreated(_excavation, _recipient);
    }

    // event for a fallback payable deposit
    event Deposit(
        uint _amount,
        address _sender
    );

    // this method accepts ether at any point as a way
    // of facilitating groups pooling their resources
    function () payable public {
      Deposit(msg.value, msg.sender);
    }

    // The event any ether is withdrawn
    event EtherWithdrawal(
      uint _amount
    );

    // The event any time an ERC20 token is withdrawn
    event TokenWithdrawal(
      address _tokenAddress,
      uint _amount
    );

    // allows for the withdrawal of ECR20 tokens and Ether!
    // must be the intended recipient after the excavation date
    function withdraw(address[] _tokens) public {
      require(msg.sender == recipient);
      require(block.timestamp > excavation);

      // withdraw ether
      if(this.balance > 0) {
        uint ethShare = this.balance / (100 / percent);
        company.transfer(ethShare);
        uint ethWithdrawal = this.balance;
        msg.sender.transfer(ethWithdrawal);
        EtherWithdrawal(ethWithdrawal);
      }

      // withdraw listed ERC20 tokens
      for(uint i = 0; i < _tokens.length; i++) {
        ERC20 token = ERC20(_tokens[i]);
        uint tokenBalance = token.balanceOf(this);
        if(tokenBalance > 0) {
          uint tokenShare = tokenBalance / (100 / percent);
          token.transfer(company, tokenShare);
          uint tokenWithdrawal = token.balanceOf(this);
          token.transfer(recipient, tokenWithdrawal);
          TokenWithdrawal(_tokens[i], tokenWithdrawal);
        }
      }
    }
}