// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Address.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract APLToken is ERC20,Ownable {
  // mapping(uint=>address) private AddressPRO;
  
  address public APL_Locked;
  address public APL_4;
  address public APL_5;
  address public APL_6;
  address public APL_7;
  address public APL_8;
  address public APL_9;

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
    // function deleteAmountwhiteList(address _AmountwhiteAddress) public onlyHuman onlyOwner returns (bool) {
    //     require(_AmountwhiteAddress!=address(0),"Zero Address");//
    //     _AmountwhiteList[_AmountwhiteAddress]=false;
    //     emit DeleteWhiteListEvent(_AmountwhiteAddress,"AmountwhiteList");
    //     return true;
    // }
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
    function setAPL_Locked(address _APL_Locked) public onlyHuman onlyOwner returns (bool) {
        require(_APL_Locked!=address(0),"Zero Address");//
        APL_Locked=_APL_Locked;
        emit SetStaticAddressEvent(_APL_Locked,"setAPL_Locked");
        return true;
    }
    function setAPL_4(address _APL_4) public onlyHuman onlyOwner returns (bool) {
        require(_APL_4!=address(0),"Zero Address");//
        APL_4=_APL_4;
        emit SetStaticAddressEvent(_APL_4,"setAPL_4");
        return true;
    }

    function setAPL_5(address _APL_5) public onlyHuman onlyOwner returns (bool) {
        require(_APL_5!=address(0),"Zero Address");//
        APL_5=_APL_5;
        emit SetStaticAddressEvent(_APL_5,"setAPL_5");
        return true;
    }

    function setAPL_6(address _APL_6) public onlyOwner returns (bool) {
        require(_APL_6!=address(0),"Zero Address");//
        APL_6=_APL_6;
        emit SetStaticAddressEvent(_APL_6,"setAPL_6");
        return true;
    }

    function setAPL_7(address _APL_7) public onlyHuman onlyOwner returns (bool) {
        require(_APL_7!=address(0),"Zero Address");//
        APL_7=_APL_7;
        emit SetStaticAddressEvent(_APL_7,"setAPL_7");
        return true;
    }

    function setAPL_8(address _APL_8) public onlyHuman onlyOwner returns (bool) {
        require(_APL_8!=address(0),"Zero Address");//
        APL_8=_APL_8;
        emit SetStaticAddressEvent(_APL_8,"setAPL_8");
        return true;
    }

    function setAPL_9(address _APL_9) public onlyHuman onlyOwner returns (bool) {
        require(_APL_9!=address(0),"Zero Address");//
        APL_9=_APL_9;
        emit SetStaticAddressEvent(_APL_9,"setAPL_9");
        return true;
    }

    function setAPL_10(address _APL_10) public onlyHuman onlyOwner returns (bool) {
        require(_APL_10!=address(0),"Zero Address");//
        APL_10=_APL_10;
        emit SetStaticAddressEvent(_APL_10,"setAPL_10");
        return true;
    }
    function setAPL_11(address _APL_11) public onlyHuman onlyOwner returns (bool) {
        require(_APL_11!=address(0),"Zero Address");//
        APL_11=_APL_11;
        emit SetStaticAddressEvent(_APL_11,"setAPL_11");
        return true;
    }
    function setAPL_12(address _APL_12) public onlyHuman onlyOwner returns (bool) {
        require(_APL_12!=address(0),"Zero Address");//
        APL_12=_APL_12;
        emit SetStaticAddressEvent(_APL_12,"setAPL_12");
        return true;
    }
    function setAPL_13(address _APL_13) public onlyHuman onlyOwner returns (bool) {
        require(_APL_13!=address(0),"Zero Address");//
        APL_13=_APL_13;
        emit SetStaticAddressEvent(_APL_13,"setAPL_13");
        return true;
    }
    
    modifier onlyHuman(){
       require(Address.isContract(_msgSender())==false,"not human address");
        _;
    }

}