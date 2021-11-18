/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity 0.5.1;

contract Traffic_light{
    uint256 teacherTime;
    uint256 startTime;
    enum State { Stop, Wait, Go }
    struct TrafLight{
        State state;
        string FirstColor;
        string SecondColor;
        string ThirdColor;
        bool Active;
    }
    address owner;
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    modifier onlyWhileOpen(){
        require(block.timestamp >= startTime ||
        block.timestamp >= teacherTime && msg.sender == 0x47C1C218f11077ef303591cb6B2056DC6ea3063F);
        _;
    }
    modifier onlyActive(){
        require(trafic_light.Active);
        _;
    }
    constructor() public{
        owner = msg.sender;
        teacherTime = 1637262910;
        startTime = 1637298000;
    }
    TrafLight public trafic_light = TrafLight(State.Wait, "Red", "Yellow" , "Green", true );
    function Enable() public onlyOwner{
        trafic_light.Active = true;
    }
    function Disable() public onlyOwner{
        trafic_light.Active = false;
    }
    function ChangeFirstColor(string memory NewColor) public onlyActive onlyWhileOpen{
        if(trafic_light.Active) trafic_light.FirstColor = NewColor;
    }
    function ChangeSecondColor(string memory NewColor) public onlyActive onlyWhileOpen{
        if(trafic_light.Active) trafic_light.SecondColor = NewColor;
    }
    function ChangeThirdColor(string memory NewColor) public onlyActive onlyWhileOpen{
       if(trafic_light.Active) trafic_light.ThirdColor = NewColor;
    }
    function Stoping() public onlyActive onlyWhileOpen{
       if(trafic_light.Active) trafic_light.state = State.Stop;
    }
    function Waiting() public onlyActive onlyWhileOpen{
       if(trafic_light.Active) trafic_light.state = State.Wait;
    }
    function Going() public onlyActive onlyWhileOpen{
       if(trafic_light.Active) trafic_light.state = State.Go;
    }
    function MayGoing() public onlyActive onlyWhileOpen returns (bool){
       if(trafic_light.Active) return trafic_light.state == State.Go; 
    }
    function ColorNow() public onlyActive onlyWhileOpen returns (string memory){
        if (trafic_light.state == State.Stop) return trafic_light.FirstColor;
        if (trafic_light.state == State.Wait) return trafic_light.SecondColor;
        if (trafic_light.state == State.Go) return trafic_light.ThirdColor;
    }
}