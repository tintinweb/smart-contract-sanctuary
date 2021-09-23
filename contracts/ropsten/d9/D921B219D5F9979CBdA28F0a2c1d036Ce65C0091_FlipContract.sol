/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

pragma solidity 0.8.7;

contract FlipContract{
    address owner;
    uint DappBalance;

    mapping(address => uint) balance;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, 'ASA, Only owner may use this function!');
        _;
    }

    modifier greaterThanZero{
        require(msg.value > 0, "ASA, value must be greater than zero!");
        _;

    }

    event bet(address user, uint bet, bool win, uint8 side);
    event funded(address owner, uint funding);
    event withdrew(address owner, uint funding);

    function flip(uint8 side) public payable  greaterThanZero returns(bool){
        require(DappBalance >= msg.value * 2, "ASA, Sorry but contract does not have enough funds to cover bet");
       
        require(side == 0 || side == 1, "ASA, Entry incorrect! side needs to be 1 or 0.");

        bool win;

        if(block.timestamp % 2 == side){

            _winner();
            win = true;

        }else{
            DappBalance+= msg.value;
            win = false;
        }

        emit bet(msg.sender, msg.value, win, side);


    }

    function _winner() private {
        uint previousDappBalance = DappBalance;
        uint reward = msg.value * 2;

        address payable userAddress = payable(msg.sender);
        
        
        DappBalance-=reward;
        userAddress.transfer(reward);
        
        
        assert(DappBalance == previousDappBalance - reward);
    }

    function withdrawDappFunds() public onlyOwner returns(uint){
        
        _withdrawDappFunds();

        assert(DappBalance == 0);
        emit withdrew(owner, DappBalance);

        return DappBalance;
    }

    function _withdrawDappFunds() private {
        
        address payable ownerAddress = payable(msg.sender);
        uint totalAmount = DappBalance;

        DappBalance-= totalAmount;

        ownerAddress.transfer(totalAmount);

    }

    function getBalance() public view returns (uint DApp_Balance) {
        
        return DappBalance;
    }

    function fundDapp() public payable onlyOwner greaterThanZero {
        uint PreviousDappBalance = DappBalance;

        DappBalance+= msg.value;

        assert(DappBalance == PreviousDappBalance + msg.value);
        emit funded(msg.sender, msg.value);
    }


}