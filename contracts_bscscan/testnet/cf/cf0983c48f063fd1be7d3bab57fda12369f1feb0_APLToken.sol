// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Address.sol";
import "./Ownable.sol";
import "./ERC20.sol";
contract APLToken is ERC20,Ownable {
// mapping(uint=>address) private AddressPRO;
// using SafeMath for uint256;

event AddWhiteListEvent(address user,string listname);
event DeleteWhiteListEvent(address user,string listname);
event SetStaticAddressEvent(address user,string func);


  constructor() ERC20("Apple Mini", "APL") {
    _mint(msg.sender, 120000000*10**18);
  }
  //Amount whiteList
    function addAmountwhiteList(address _AmountwhiteAddress) public onlyHuman onlyOwner returns (bool) {
        require(_AmountwhiteAddress!=address(0),"Zero Address");//
        _AmountwhiteList[_AmountwhiteAddress]=true;
        emit AddWhiteListEvent(_AmountwhiteAddress,"AmountwhiteList");
        return true;
    }
     function isInAmountwhiteList(address _AmountwhiteAddress) public view returns (bool) {
        return _AmountwhiteList[_AmountwhiteAddress];
    }
    //Tx whiteList
    function addTxwhiteList(address _TxwhiteAddress) public onlyHuman onlyOwner returns (bool) {
        require(_TxwhiteAddress!=address(0),"Zero Address");//
        _TxwhiteList[_TxwhiteAddress]=true;
        emit AddWhiteListEvent(_TxwhiteAddress,"TxwhiteList");
        return true;
    }
    function deleteTxwhiteList(address _TxwhiteAddress) public onlyHuman onlyOwner returns (bool) {
        require(_TxwhiteAddress!=address(0),"Zero Address");//
        _TxwhiteList[_TxwhiteAddress]=false;
        emit DeleteWhiteListEvent(_TxwhiteAddress,"TxwhiteList");
        return true;
    }
     function isInTxwhiteList(address _TxwhiteAddress) public view returns (bool) {
        return _TxwhiteList[_TxwhiteAddress];
    }
     
  /*set  
    set your APL_Locked
  */
    function setAPL_Best_Promoter_share(address _APL_Best_Promoter_share) public onlyHuman onlyOwner returns (bool) {
        APL_Best_Promoter_share=_APL_Best_Promoter_share;
        emit SetStaticAddressEvent(_APL_Best_Promoter_share,"setAPL_Best_Promoter_share");
        return true;
    }
    function setAPL_Super_Node_share(address _APL_Super_Node_share) public onlyHuman onlyOwner returns (bool) {
        APL_Super_Node_share=_APL_Super_Node_share;
        emit SetStaticAddressEvent(_APL_Super_Node_share,"setAPL_Super_Node_share");
        return true;
    }
    function setAPL_Foundation_share(address _APL_Foundation_share) public onlyHuman onlyOwner returns (bool) {
        APL_Foundation_share=_APL_Foundation_share;
        emit SetStaticAddressEvent(_APL_Foundation_share,"setAPL_Foundation_share");
        return true;
    }
    function setAPL_LP_share(address _APL_LP_share) public onlyHuman onlyOwner returns (bool) {
        APL_LP_share=_APL_LP_share;
        emit SetStaticAddressEvent(_APL_LP_share,"setAPL_LP_share");
        return true;
    }
    function setAPL_Airdrop_share(address _APL_Airdrop_share) public onlyHuman onlyOwner returns (bool) {
        APL_Airdrop_share=_APL_Airdrop_share;
        emit SetStaticAddressEvent(_APL_Airdrop_share,"setAPL_Airdrop_share");
        return true;
    }
   
    modifier onlyHuman(){
       require(Address.isContract(_msgSender())==false,"not human address");
       _;
    }

}