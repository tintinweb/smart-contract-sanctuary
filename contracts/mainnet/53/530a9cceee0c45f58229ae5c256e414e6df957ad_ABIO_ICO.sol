pragma solidity ^0.4.24;
contract Ownable{
    address public owner;
    event ownerTransfer(address indexed oldOwner, address indexed newOwner);
    event ownerGone(address indexed oldOwner);

    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    function changeOwner(address _newOwner) public onlyOwner{
        require(_newOwner != address(0x0));
        emit ownerTransfer(owner, _newOwner);
        owner = _newOwner;
    }
}
contract Haltable is Ownable{
    bool public paused;
    event ContractPaused(address by);
    event ContractUnpaused(address by);

    /**
     * @dev Paused by default.
     */
    constructor(){
        paused = true;
    }
    function pause() public onlyOwner {
        paused = true;
        emit ContractPaused(owner);
    }
    function unpause() public onlyOwner {
        paused = false;
        emit ContractUnpaused(owner);
    }
    modifier stopOnPause(){
        if(msg.sender != owner){
            require(paused == false);
        }
        _;
    }
}
interface ABIO_Token {
    function owner() external returns (address);
    function transfer(address receiver, uint amount) external;
    function burnMyBalance() external;
}
interface ABIO_preICO{
    function weiRaised() external returns (uint);
    function fundingGoal() external returns (uint);
    function extGoalReached() external returns (uint);
}
contract ABIO_BaseICO is Haltable{
    mapping(address => uint256) ethBalances;

    uint public weiRaised;//total raised in wei
    uint public abioSold;//amount of ABIO sold
    uint public volume; //total amount of ABIO selling in this preICO

    uint public startDate;
    uint public length;
    uint public deadline;
    bool public restTokensBurned;

    uint public weiPerABIO; //how much wei one ABIO costs
    uint public minInvestment;
    uint public fundingGoal;
    bool public fundingGoalReached;
    address public treasury;

    ABIO_Token public abioToken;

    event ICOStart(uint volume, uint weiPerABIO, uint minInvestment);
    event SoftcapReached(address recipient, uint totalAmountRaised);
    event FundsReceived(address backer, uint amount);
    event FundsWithdrawn(address receiver, uint amount);

    event ChangeTreasury(address operator, address newTreasury);
    event PriceAdjust(address operator, uint multipliedBy ,uint newMin, uint newPrice);

         /**
         * @notice allows owner to change the treasury in case of hack/lost keys.
         * @dev Marked external because it is never called from this contract.
         */
         function changeTreasury(address _newTreasury) external onlyOwner{
             treasury = _newTreasury;
             emit ChangeTreasury(msg.sender, _newTreasury);
         }

         /**
         * @notice allows owner to adjust `minInvestment` and `weiPerABIO` in case of extreme jumps of Ether&#39;s dollar-value.
         * @param _multiplier Both `minInvestment` and `weiPerABIO` will be multiplied by `_multiplier`. It is supposed to be close to oldEthPrice/newEthPrice
         * @param _multiplier MULTIPLIER IS SUPPLIED AS PERCENTAGE
         */
         function adjustPrice(uint _multiplier) external onlyOwner{
             require(_multiplier < 400 && _multiplier > 25);
             minInvestment = minInvestment * _multiplier / 100;
             weiPerABIO = weiPerABIO * _multiplier / 100;
             emit PriceAdjust(msg.sender, _multiplier, minInvestment, weiPerABIO);
         }

         /**
          * @notice Called everytime we receive a contribution in ETH.
          * @dev Tokens are immediately transferred to the contributor, even if goal doesn&#39;t get reached.
          */
         function () payable stopOnPause{
             require(now < deadline);
             require(msg.value >= minInvestment);
             uint amount = msg.value;
             ethBalances[msg.sender] += amount;
             weiRaised += amount;
             if(!fundingGoalReached && weiRaised >= fundingGoal){goalReached();}

             uint ABIOAmount = amount / weiPerABIO ;
             abioToken.transfer(msg.sender, ABIOAmount);
             abioSold += ABIOAmount;
             emit FundsReceived(msg.sender, amount);
         }

         /**
         * @notice We implement tokenFallback in case someone decides to send us tokens or we want to increase ICO Volume.
         * @dev If someone sends random tokens transaction is reverted.
         * @dev If owner of token sends tokens, we accept them.
         * @dev Crowdsale opens once this contract gets the tokens.
         */
         function tokenFallback(address _from, uint _value, bytes) external{
             require(msg.sender == address(abioToken));
             require(_from == abioToken.owner() || _from == owner);
             volume = _value;
             paused = false;
             deadline = now + length;
             emit ICOStart(_value, weiPerABIO, minInvestment);
         }

         /**
         * @notice Burns tokens leftover from an ICO round.
         * @dev This can be called by anyone after deadline since it&#39;s an essential and inevitable part.
         */
         function burnRestTokens() afterDeadline{
                 require(!restTokensBurned);
                 abioToken.burnMyBalance();
                 restTokensBurned = true;
         }

         function isRunning() view returns (bool){
             return (now < deadline);
         }

         function goalReached() internal;

         modifier afterDeadline() { if (now >= deadline) _; }
}


contract ABIO_ICO is ABIO_BaseICO{
    ABIO_preICO PICO;
    uint weiRaisedInPICO;
    uint abioSoldInPICO;

    event Prolonged(address oabiotor, uint newDeadline);
    bool didProlong;
    constructor(address _abioAddress, address _treasury, address _PICOAddr, uint _lenInMins,uint _minInvestment, uint _priceInWei){
         abioToken = ABIO_Token(_abioAddress);
         treasury = _treasury;

         PICO = ABIO_preICO(_PICOAddr);
         weiRaisedInPICO = PICO.weiRaised();
         fundingGoal = PICO.fundingGoal();
         if (weiRaisedInPICO >= fundingGoal){
             goalReached();
         }
         minInvestment = _minInvestment;

         startDate = now;
         length = _lenInMins * 1 minutes;
         weiPerABIO = _priceInWei;
         fundingGoal = PICO.fundingGoal();
    }

    /**
    * @notice a function that changes state if goal reached. If the PICO didn&#39;t reach goal, it reports back to it.
    */
    function goalReached() internal {
        emit SoftcapReached(treasury, fundingGoal);
        fundingGoalReached = true;
        if (weiRaisedInPICO < fundingGoal){
            PICO.extGoalReached();
        }
    }

    /**
     * @notice Lets participants withdraw the funds if goal was missed.
     * @notice Lets treasury collect the funds if goal was reached.
     * @dev The contract is obligated to return the ETH to contributors if goal isn&#39;t reached,
     *      so we have to wait until the end for a withdrawal.
     */
    function safeWithdrawal() afterDeadline stopOnPause{
        if (!fundingGoalReached) {
            uint amount = ethBalances[msg.sender];
            ethBalances[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    emit FundsWithdrawn(msg.sender, amount);
                } else {
                    ethBalances[msg.sender] = amount;
                }
            }
        }
        else if (fundingGoalReached) {
            require(treasury == msg.sender);
            if (treasury.send(weiRaised)) {
                emit FundsWithdrawn(treasury, weiRaised);
            } else if (treasury.send(address(this).balance)){
                emit FundsWithdrawn(treasury, address(this).balance);
            }
        }
    }

    /**
    * @notice Is going to be called in an extreme case where we need to prolong the ICO (e.g. missed Softcap by a few ETH)/
    * @dev It&#39;s only called once, has to be called at least 4 days before ICO end and prolongs the ICO for no more than 3 weeks.
    */
    function prolong(uint _timeInMins) external onlyOwner{
        require(!didProlong);
        require(now <= deadline - 4 days);
        uint t = _timeInMins * 1 minutes;
        require(t <= 3 weeks);
        deadline += t;
        length += t;

        didProlong = true;
        emit Prolonged(msg.sender, deadline);
    }
}