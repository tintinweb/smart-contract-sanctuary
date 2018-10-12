pragma solidity ^0.4.25;
/**
*
* ETH CRYPTOCURRENCY DISTRIBUTION PROJECT
* Web              - https://doeth.io/
* Twitter          - https://twitter.com/eth_do
* Telegram_channel - https://t.me/joinchat/JnIiXhAlqjy-7FYaMRso1g
*
*  - GAIN 4% PER 24 HOURS (every 5900 blocks)
*  - Life-long payments
*  - The revolutionary reliability
*  - Minimal contribution 0.01 eth
*  - Currency and payment - ETH
*  - Contribution allocation schemes:
*    -- 85% payments
*    -- 15% Marketing + Operating Expenses
*
*   ---About the Project
*  Blockchain-enabled smart contracts have opened a new era of trustless relationships without
*  intermediaries. This technology opens incredible financial possibilities. Our automated investment
*  distribution model is written into a smart contract, uploaded to the Ethereum blockchain and can be
*  freely accessed online. In order to insure our investors&#39; complete security, full control over the
*  project has been transferred from the organizers to the smart contract: nobody can influence the
*  system&#39;s permanent autonomous functioning.
*
* ---How to use:
*  1. Send from ETH wallet to the smart contract address 0x0ff434793ba552db7861064ccb0268a9c05a20d2
*     any amount from 0.01 ETH.
*  2. Verify your transaction in the history of your application or etherscan.io, specifying the address
*     of your wallet.
*  3a. Claim your profit by sending 0 ether transaction (every day, every week, i don&#39;t care unless you&#39;re
*      spending too much on GAS)
*  OR
*  3b. For reinvest, you need to first remove the accumulated percentage of charges (by sending 0 ether
*      transaction), and only after that, deposit the amount that you want to reinvest.
* 
* RECOMMENDED GAS LIMIT: 200000
* RECOMMENDED GAS PRICE: https://ethgasstation.info/
* You can check the payments on the etherscan.io site, in the "Internal Txns" tab of your wallet.
*
* ---It is not allowed to transfer from exchanges, only from your personal ETH wallet, for which you
* have private keys.
*
* Contracts reviewed and approved by pros!
*
* Main contract - DOETH.
*/
library SafeMath {
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    if (_a == 0) {
      return 0;
    }
    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a / _b;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract DOETH {
    using SafeMath for uint256;

    address public constant marketingAddress = 0x2dB7088799a5594A152c8dCf05976508e4EaA3E4;

    mapping (address => uint256) deposited;
    mapping (address => uint256) withdrew;
    mapping (address => uint256) refearned;
    mapping (address => uint256) blocklock;

    uint256 public totalDepositedWei = 0;
    uint256 public totalWithdrewWei = 0;

    function() payable external
    {
        uint256 marketingPerc = msg.value.mul(15).div(100);

        marketingAddress.transfer(marketingPerc);
        
        if (deposited[msg.sender] != 0)
        {
            address investor = msg.sender;
            uint256 depositsPercents = deposited[msg.sender].mul(4).div(100).mul(block.number-blocklock[msg.sender]).div(5900);
            investor.transfer(depositsPercents);

            withdrew[msg.sender] += depositsPercents;
            totalWithdrewWei = totalWithdrewWei.add(depositsPercents);
        }

        address referrer = bytesToAddress(msg.data);
        uint256 refPerc = msg.value.mul(4).div(100);
        
        if (referrer > 0x0 && referrer != msg.sender)
        {
            referrer.transfer(refPerc);

            refearned[referrer] += refPerc;
        }

        blocklock[msg.sender] = block.number;
        deposited[msg.sender] += msg.value;

        totalDepositedWei = totalDepositedWei.add(msg.value);
    }

    function userDepositedWei(address _address) public view returns (uint256)
    {
        return deposited[_address];
    }

    function userWithdrewWei(address _address) public view returns (uint256)
    {
        return withdrew[_address];
    }

    function userDividendsWei(address _address) public view returns (uint256)
    {
        return deposited[_address].mul(4).div(100).mul(block.number-blocklock[_address]).div(5900);
    }

    function userReferralsWei(address _address) public view returns (uint256)
    {
        return refearned[_address];
    }

    function bytesToAddress(bytes bys) private pure returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}