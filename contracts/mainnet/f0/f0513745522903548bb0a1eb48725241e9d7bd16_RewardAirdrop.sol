pragma solidity >0.4.99 <0.6.0;

interface token {
    function balanceOf(address _owner) external returns (uint balance);
    function transfer(address _to, uint256 _value) external;
    function transferFrom(address _from, address _to, uint256 _value) external;
}

contract RewardAirdrop {
    address public owner = msg.sender;
    address tokenAddress = 0x46706C5e5B7dF0Afd54a7248F1E5788275B7FaC6;
    token public tokenReward = token(tokenAddress);

    address usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    token public stableCoinReward = token(usdcAddress);

    uint public stableCoinPrice = 10 ** 16;
    uint public totalRewardBalance = 0;

    // keeps track of rewards given
    mapping (bytes32 => bool) public airdrops;
    mapping(address => uint256) public rewardBalanceOf;

    modifier onlyOwner() {require(msg.sender == owner); _;}

    function() payable external {}

    function airdropTokens(bytes32 _channelId, address[] memory _recipients, uint tokenAmount, uint weiAmount) public onlyOwner {
        for(uint i = 0; i < _recipients.length; i++)
        {
            bytes32 channelHash = keccak256(
                abi.encodePacked(_channelId, _recipients[i])
            );

            address payable currentRecipient = address(uint160(_recipients[i]));
            
            if (!airdrops[channelHash]) {
                airdrops[channelHash] = true;
                rewardBalanceOf[currentRecipient] += tokenAmount;
                totalRewardBalance += tokenAmount;
                tokenReward.transfer(currentRecipient, tokenAmount);
                currentRecipient.transfer(weiAmount);
            }
        }
    }

    function sendStableReward(address _from, address _destination, uint _tokenAmount, uint _stableCoinAmount) public onlyOwner{
        require(rewardBalanceOf[_from]>= _tokenAmount);
        tokenReward.transferFrom(_from, address(this), _tokenAmount);
        rewardBalanceOf[_from] -= _tokenAmount;
        totalRewardBalance -= _tokenAmount;
        stableCoinReward.transfer(_destination, _stableCoinAmount);
    }

    function changeDollarPrice(uint _newPrice) public onlyOwner {
        stableCoinPrice = _newPrice;
    }

    function withdraw(uint _weiAmount)
      onlyOwner
      public
    {
        address payable wallet = address(uint160(owner));

        wallet.transfer(_weiAmount);
    }

    function withdrawTokens(uint _tokenAmount) onlyOwner public {

        tokenReward.transfer(owner, _tokenAmount);
    }

     function withdrawAllEther()
      onlyOwner
      public
    {
        address payable wallet = address(uint160(owner));
        address contractAddress = address(this);
        wallet.transfer(contractAddress.balance);
    }

    function withdrawAllTokens() onlyOwner public {
        uint tokenBalance = tokenReward.balanceOf(address(this));

        tokenReward.transfer(owner, tokenBalance);
    }

    function destroy() onlyOwner public {
        selfdestruct(address(this));
    }
}