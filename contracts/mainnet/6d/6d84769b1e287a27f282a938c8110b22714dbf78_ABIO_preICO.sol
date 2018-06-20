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
        require(paused == false);
        _;
    }
}
interface ABIO_Token {
    function owner() external returns (address);
    function transfer(address receiver, uint amount) external;
    function burnMyBalance() external;
}
interface ABIO_ICO{
    function deadline() external returns (uint);
    function weiRaised() external returns (uint);
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
    event ChangeMinInvestment(address operator, uint oldMin, uint newMin);

         /**
         * @notice allows owner to change the treasury in case of hack/lost keys.
         * @dev Marked external because it is never called from this contract.
         */
         function changeTreasury(address _newTreasury) external onlyOwner{
             treasury = _newTreasury;
             emit ChangeTreasury(msg.sender, _newTreasury);
         }

         /**
         * @notice allows owner to change the minInvestment in case of extreme price jumps of ETH price.
         */
         function changeMinInvestment(uint _newMin) external onlyOwner{
             emit ChangeMinInvestment(msg.sender, minInvestment, _newMin);
             minInvestment = _newMin;
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
         function tokenFallback(address _from, uint _value, bytes _data) external{
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
contract ABIO_preICO is ABIO_BaseICO{
    address ICOAddress;
    ABIO_ICO ICO;
    uint finalDeadline;

    constructor(address _abioAddress, uint _lenInMins, uint _minWeiInvestment, address _treasury, uint _priceInWei, uint _goalInWei){
        treasury = _treasury;
        abioToken = ABIO_Token(_abioAddress);

        weiPerABIO = _priceInWei;
        fundingGoal = _goalInWei;
        minInvestment = _minWeiInvestment;

        startDate = now;
        length = _lenInMins * 1 minutes;
     }
     /**
     * @notice Called by dev to supply the address of the ICO (which is created after the PreICO)
     * @dev We check if `fundingGoal` is reached again, because this MIGHT be called after it is reached, so `extGoalReached()` will never be called after.
     */
    function supplyICOContract(address _addr) public onlyOwner{
        require(_addr != 0x0);
        ICOAddress = _addr;
        ICO = ABIO_ICO(_addr);
        if(!fundingGoalReached && weiRaised + ICO.weiRaised() >= fundingGoal){goalReached();}
        finalDeadline = ICO.deadline();
    }

    function goalReached() internal{
        fundingGoalReached = true;
        emit SoftcapReached(treasury, fundingGoal);
    }

    /**
    * @notice supposed to be called by ICO Contract IF `fundingGoal` wasn&#39;t reached during PreICO to notify it
    * @dev !!Funds can&#39;t be deposited to treasury if `fundingGoal` isn&#39;t called before main ICO ends!!
    * @dev This is, at max., called once! If this contract doesn&#39;t know ICOAddress by that time, we rely on the check in `supplyICOContract()`
    */
    function extGoalReached() afterDeadline external{
        require(ICOAddress != 0x0); //ICO was supplied
        require(msg.sender == ICOAddress);
        goalReached();
    }

    /**
     * @notice Lets participants withdraw the funds if `fundingGoal` was missed.
     * @notice Lets treasury collect the funds if `fundingGoal` was reached.
     * @dev The contract is obligated to return the ETH to contributors if `fundingGoal` isn&#39;t reached,
     *      so we have to wait until the end for a user withdrawal.
     * @dev The treasury can withdraw right after `fundingGoal` is reached.
     */
    function safeWithdrawal() afterDeadline stopOnPause{
        if (!fundingGoalReached && now >= finalDeadline) {
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
        else if (fundingGoalReached && treasury == msg.sender) {
            if (treasury.send(weiRaised)) {
                emit FundsWithdrawn(treasury, weiRaised);
            } else if (treasury.send(address(this).balance)){
                emit FundsWithdrawn(treasury, address(this).balance);
            }
        }
    }

}