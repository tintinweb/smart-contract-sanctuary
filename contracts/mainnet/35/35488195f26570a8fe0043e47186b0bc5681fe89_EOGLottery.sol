////////////////////////////////////////////////////
//******** In the name of god **********************
//******** https://Helixnebula.help  ***************
////p2p blockchain based helping system/////////////
////////////Lottery for EOG Holders/////////////////
//This is an endless profitable cycle for everyone//
////Contact us: support@helixnebula.help////////////
////////////////////////////////////////////////////

pragma solidity ^0.5.0;
contract EIP20Interface {
    
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);
}
contract EOGLottery
{
    address EOGAddress=0x8Ae6AE8F172d7fc103CCfa5890883d6fE46038C9;
    address owner;
    address public LastMaxWinner;
    address public LastLotteryWinner;
    uint public MinEOG = 5*10**18;
    uint private seed;
    uint public ChargedETH;
    address payable[]  private Competitors;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    constructor() public {
        owner=msg.sender;
    }
    function transferOwnership(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }
    function GetUserPoints(address _adr) external view returns(uint){
        for(uint i=0 ;i < Competitors.length;i++){
            if( _adr==Competitors[i]){
                return EIP20Interface(EOGAddress).balanceOf(_adr);
            }
        }
        return 0;
    }
    function ChangeMinEog(uint _newval,uint _seed) external onlyOwner{
        MinEOG=_newval;
        seed=_seed;
    }
    
    function GetPoints() public view returns(uint){
        uint Maxrand=0;
        for(uint i=0 ;i < Competitors.length;i++){
            if( EIP20Interface(EOGAddress).balanceOf(Competitors[i])>MinEOG){
                Maxrand += EIP20Interface(EOGAddress).balanceOf(Competitors[i])/(10**13);
            }
        }
        return Maxrand;
    }
    function chargeLottery() public payable {
        ChargedETH=msg.value;
    }
    function Random(uint max) public view returns(uint){
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty,Competitors.length,seed))) % max;
        return randomnumber;
    }
    function GetMaxHolder() public view returns(address payable){
       address payable MaxHolder;
       MaxHolder=Competitors[0];
        for(uint i=1 ;i < Competitors.length;i++){
            if( EIP20Interface(EOGAddress).balanceOf(MaxHolder)<EIP20Interface(EOGAddress).balanceOf(Competitors[i])){
                MaxHolder=Competitors[i];
            }
        }
        return MaxHolder;
    }
    function StartLottery() external onlyOwner{
        uint RandNum=Random(GetPoints());
        uint counter=0;
        for(uint i=0 ;i < Competitors.length;i++){
            if( EIP20Interface(EOGAddress).balanceOf(Competitors[i])>MinEOG){
                uint tempnum=EIP20Interface(EOGAddress).balanceOf(Competitors[i])/(10**13);
                if(RandNum < counter+tempnum && RandNum >= counter){
                    //uint256 Balance=address(this).balance;
                    if(Competitors[i] != LastLotteryWinner){
                        Competitors[i].transfer((address(this).balance/4)*3);
                        LastLotteryWinner=Competitors[i];
                    }
                    if(Competitors[i] != LastMaxWinner){
                        address payable MaxHold=GetMaxHolder();
                        MaxHold.transfer(address(this).balance);
                        LastMaxWinner=MaxHold;
                    }
                }else{
                    counter += EIP20Interface(EOGAddress).balanceOf(Competitors[i])/(10**13);
                }
            }
        }
    }
    function ExistCompetitor(address _adr) internal view returns(bool){
        for(uint i=0 ;i < Competitors.length;i++){
            if(Competitors[i]==_adr){
                return true;
            }
        }
        return false;
    }
    function Register() public {
        require(EIP20Interface(EOGAddress).balanceOf(msg.sender)>=MinEOG);
        require(ExistCompetitor(msg.sender) == false);
        Competitors.push(msg.sender);
    }
    
}