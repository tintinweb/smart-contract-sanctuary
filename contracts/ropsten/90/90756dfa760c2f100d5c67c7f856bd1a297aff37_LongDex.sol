pragma solidity ^0.4.11;


//contract dinh nghia ICO keu goi von bang cach: ng mua gui ETH vao contract nay va nhan dc lai token co phieu theo ti le rate co san
contract DFSTokenInterface{
    uint256 public totalSupply;
    function () public payable;
    function balanceOf(address _owner) constant public returns(uint256);
    function transfer(address _to, uint256 _value) public returns(bool);
}

contract LongDex {

    DFSTokenInterface DFSToken;
    uint256 public fundingGoal;
    /* uint DateStage1End = 1529445600;   // 19-6-2018 22:00:00
    uint deadline = 1531864800;       // 15-77-2018 22:00:00 */
    uint DateStage1End = 1528562100;
    uint deadline = 1528562400;
    uint256 public tokenSale;
    uint256 public tokenLeft = 2000 ;
    address beneficiary;
    //Main ETH Wallet&#39;s address: 0xaF685b7C8fF0B34e706758d61991716f058cB685
    bool fundingGoalReached = false;
    uint256 public rate = 100;

    modifier onlyValidAddress(address _to){
        require(_to != address(0x00));
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == beneficiary);
        _;
    }

    function checkStage1Over() internal {
      if (now >= DateStage1End){
        rate = 6000;
      }
    }

    function setRate(uint256 _rate)
    onlyOwner public returns(uint256){
        rate = _rate;
        return rate;
    }

    /**
     * Constructor function
     *
     * Setup the owner
     */
    function LongDex() public {
        DFSToken = DFSTokenInterface(0xD94135082B996e2d86dDe0515B58DD1e89E48062);// dien dia chi token co phieu
        fundingGoal = 2000;
        beneficiary = 0xa1c510d39842C44F7dC728b8d9B1204d3e22226b; //account nhan tien ETH cua ng mua co phieu gui vao contract dex
    }


    function ()
       external payable {
           //require (now <= deadline && tokenLeft > 0);
          require (tokenLeft > 0);
          //checkStage1Over();
          uint amount = msg.value;
          uint256 _value = rate * amount;
          require (_value <= tokenLeft);
          require((tokenSale + _value)  < fundingGoal);
          tokenSale += _value;
          tokenLeft -= _value;
          assert(DFSToken.transfer(msg.sender, _value));
          beneficiary.transfer(msg.value);
    }
}