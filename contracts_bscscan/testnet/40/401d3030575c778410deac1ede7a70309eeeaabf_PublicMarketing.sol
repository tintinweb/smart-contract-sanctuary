/**
 *Submitted for verification at BscScan.com on 2021-08-22
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

interface BEP20 {

  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PublicMarketing{
    
    address[] multiMarketing;
    address _owner = 0xE75527f4A89Ad180826Ebf9a30b706ab5cA505b6;
    

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyMarketing() {
        require( msg.sender == team[msg.sender].addres, "Ownable: caller is not the marketing");
        _;
    }
    
    mapping(address => Team) team;
    
    struct Team {
        bool add;
        string telegram;
        address addres;
        uint256 total;
    }
    
    function setNewOwner(address _newOwner) public onlyOwner{
        _owner = _newOwner;
    }

    function getMyFees() public view returns(uint256){
        uint256 feeGet = address(this).balance / multiMarketing.length;
        return feeGet;
    }
    
    function owner() public view returns (address) {
        return _owner;
    }  
    
    function addNewPublicMarketing(address newMarketing, string memory telegram) public onlyOwner{
        
        require( !team[newMarketing].add, 'address has been added !!');
        
        if(address(this).balance != 0) shareFee();
        
        team[newMarketing].add = true;
        team[newMarketing].telegram = telegram;
        team[newMarketing].addres = newMarketing;
        team[newMarketing].total = 0;
        multiMarketing.push(newMarketing);
        
    }
    
    function getAllMarketingLength() public view returns(uint){
        return multiMarketing.length;
    }
    
    function removeMarktingByAddress(address marketingAddress) public onlyOwner{
        
         if(address(this).balance != 0) shareFee();
        
         for(uint a = 0 ;a< multiMarketing.length;a++){
             if(multiMarketing[a] == marketingAddress){
                 multiMarketing[a] = multiMarketing[multiMarketing.length - 1];
                 multiMarketing.pop();
             }
         }
     }
     
     function readMarketingById(uint _id) public view returns(address, string memory, uint256){
         require(msg.sender == team[msg.sender].addres || msg.sender == _owner, 'only admin');
         address tim = multiMarketing[_id];
         Team storage teams = team[tim];
         return (teams.addres, teams.telegram, teams.total);
     }
     
     function tranferFeeToMultimarketing(uint256 amount) internal {
         uint256 calculatePerOne = amount / multiMarketing.length;
         for(uint a = 0;a < multiMarketing.length;a++){
             address payable _to_ = payable( multiMarketing[a] );
             team[ multiMarketing[a] ].total += calculatePerOne;
             _to_.transfer(calculatePerOne);
         }
     }
     
     function balance() public view returns(uint256){
         return address(this).balance;
     }
     
     function shareBEP20token(address bep20Token) public onlyMarketing{
         
         uint256 amount = BEP20(bep20Token).balanceOf(address(this));
         uint256 calculatePerOne = amount / multiMarketing.length;
         for(uint a = 0;a < multiMarketing.length;a++){
             address _to_ =  multiMarketing[a];
             BEP20(bep20Token).transfer(_to_, calculatePerOne);
         }
         
     }
     
     function shareFee() public{
         tranferFeeToMultimarketing(address(this).balance);
     }

}