pragma solidity ^0.4.19;

contract Payeth  {
    // 議論点
    // stringtとbytes32はどう使い分けるべきか
    // eventをemitする必要はあるのか
    // eventの引数にindexedはつけたほうが良いのか
    // creatorBalanceはpublicで良いのか
    mapping (address => mapping (bytes32 =>uint)) public paidAmount;
    mapping (address => uint) public creatorBalances;
    
    event PayForUrl(address _from, address _creator, string _url, uint amount);
    event Withdraw(address _from, uint amount);
    function payForUrl(address _creator,string _url) public payable {
        creatorBalances[_creator] += msg.value;
        paidAmount[msg.sender][keccak256(_url)] += msg.value;
        emit PayForUrl(msg.sender,_creator,_url,msg.value);
    }
    function withdraw() public{
        uint balance = creatorBalances[msg.sender];
        require(balance > 0);
        creatorBalances[msg.sender] = 0;
        msg.sender.transfer(balance);
        emit Withdraw(msg.sender, balance);
    }
}