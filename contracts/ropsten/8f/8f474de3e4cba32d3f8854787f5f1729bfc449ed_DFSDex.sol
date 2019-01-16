pragma solidity ^0.4.11;

contract DFSTokenInterface{
    uint256 public totalSupply;
    function () public payable;
    function balanceOf(address _owner) constant public returns(uint256);
    function transfer(address _to, uint256 _value) public returns(bool);
}

contract DFSDex {

    DFSTokenInterface DFSToken;
    uint256 public fundingGoal;
    /* uint DateStage1End = 1529445600;   // 19-6-2018 22:00:00
    uint deadline = 1531864800;       // 15-77-2018 22:00:00 */
    uint DateStage1End = 1528562100;
    uint deadline = 1528562400;
    uint256 public tokenSale;
    uint256 public tokenLeft = 200000000 ;
    address beneficiary;
    //Main ETH Wallet&#39;s address: 0xaF685b7C8fF0B34e706758d61991716f058cB685
    bool fundingGoalReached = false;
    uint256 public rate = 8000;

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
    function DFSDex() public {
        DFSToken = DFSTokenInterface(0x52F3402fB6e628079aCBB9201FcE88859c79D6C9);// DFStoken
        fundingGoal = 200000000;
        beneficiary = 0xa1c510d39842C44F7dC728b8d9B1204d3e22226b; //account 1
    }


    function ()
       external payable {
           //require (now <= deadline && tokenLeft > 0);
          require (tokenLeft > 0);
          //checkStage1Over();
          uint amount = msg.value;
          uint256 _value = (amount*rate)/10**18;
          require (_value <= tokenLeft);
          require((tokenSale + _value)  < fundingGoal);
          tokenSale += _value;
          tokenLeft -= _value;
          assert(DFSToken.transfer(msg.sender, _value));
          beneficiary.transfer(msg.value);
    }
}