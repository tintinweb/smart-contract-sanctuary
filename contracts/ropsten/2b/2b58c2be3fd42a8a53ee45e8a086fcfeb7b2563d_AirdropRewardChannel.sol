pragma solidity ^0.4.21;

// Airdrop Wallet and gas management service

interface token {
    function transfer(address _to, uint256 _value) external;
}

contract AirdropRewardChannel {
    address public faucet = msg.sender;
    address tokenAddress = 0xebc5b45f1c763560bff823c2aba85e1935a352d4;
    token public tokenReward= token(tokenAddress);


    // keeps track of rewards given
    mapping (bytes32 => bool) public airdrops;

    modifier onlyBy(address _account) {require(msg.sender == _account); _;}

    function() payable public {}


    function airdropTokens(bytes32 _channelId, address[] _recipients, uint tokenAmount) public onlyBy(faucet) {
        for(uint i = 0; i < _recipients.length; i++)
        {
            bytes32 channelHash = keccak256(
                abi.encodePacked(_channelId, _recipients[i])
            );
            
            if (!airdrops[channelHash]) {
                airdrops[channelHash] = true;
                tokenReward.transfer(_recipients[i], tokenAmount);
            }
        }
    }


    function withdraw()
      onlyBy(faucet)
      public
    {
        address contractAddress = this;
        faucet.transfer(contractAddress.balance);
    }

    function destroy() onlyBy(faucet) public {
        selfdestruct(this);
    }
}