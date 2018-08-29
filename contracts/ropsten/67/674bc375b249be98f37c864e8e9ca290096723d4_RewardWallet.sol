pragma solidity ^0.4.21;

// Reward Wallet

interface token {
    function transfer(address _to, uint256 _value) external;
    function balanceOf(address _owner) external constant returns (uint balance);
}

contract RewardWallet {
    address public owner = msg.sender;
    address public faucet;

    mapping (address => uint256) public balanceOf;


    token public tokenReward;
    uint256 public valueInEth;

    modifier onlyBy(address _account) {require(msg.sender == _account); _;}

    function RewardWallet( address addressOfTokenUsedAsReward, address faucetAddress, uint256 amountInSzabos) public {
        faucet = faucetAddress;
        tokenReward = token(addressOfTokenUsedAsReward);
        valueInEth = amountInSzabos * 1 szabo;
    }

    function() payable public {}

    // channel id 
    // keccak256((address channelFunder, string model, uint capacity))

   
    function sendEther(address _from, address _to, uint amount)
      onlyBy(faucet)
      public
    {
        require(balanceOf[_from] * valueInEth >= amount * valueInEth);      // checks if the contract has enough ether to buy

        _to.transfer(amount * valueInEth);
    }

    function sendToken(address _from, address _to, uint amount)
      onlyBy(faucet)
      public
    {

        require(balanceOf[_from] >= amount );      // checks if the contract has enough ether to buy
        tokenReward.transfer(_to, amount);
    }

    function setConversionRate(uint256 amountInSzabos)
      onlyBy(faucet)
      public
    {
        valueInEth = amountInSzabos * 1 szabo;
    }

    function reward(address _user)
      onlyBy(faucet)
      public
    {
        balanceOf[_user] += 1 ether;
    }

    // function verifyHash(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) 
    //   public
    //   pure
    //   returns (address) 
    // {
    // //   bytes32 channelData = keccak256(_hash, _h);
    //     address signer = ecrecover(_hash, _v, _r, _s);
    //     return signer;
    // }

    function withdraw()
      onlyBy(owner)
      public
    {
        address contractAddress = this;
        owner.transfer(contractAddress.balance);
    }

    function destroy() onlyBy(owner) public {
        selfdestruct(this);
    }
}