pragma solidity >=0.4.21 <0.6.0;

import "./Owned.sol";
import "./TokenERC20.sol";

contract YouLingCoin is owned, TokenERC20 {

       uint public sendAmount; //总的出币数
       uint public dhRate;  //兑换比例
       uint public sxfAmount; //收取的手续费总额
       uint public kcRate; //矿池手续费比例
       uint public ktAmount; //剩余空投金额
       address[] public bigPoint;//大节点
       address[] public smallPoint;//小节点
       uint public ethAmount;//合约中以太数量
           struct userInfo{
               address parentAddress; //父地址
               address myAddress;//我的地址
               uint  kcAmount; //矿池数
               bool isUsed; //是否使用
           }
    mapping (address => userInfo[])  ztUser; //直推信息
    mapping (address => userInfo[])  tdUser; //团队信息
    mapping (address => userInfo)  userInfos; //会员信息
    mapping (uint => address) userIds;//会员ID

    mapping(uint => uint) div;//总层数
    mapping(uint => uint) rate;//兑换费率
   // uint[] public div;
    //    uint[] public rate;

    uint public nowDiv;//现层数
    uint public sumAmount;//总得兑币数
    uint public kcSxfAmount;
    uint public smallPointCount;
    uint public bigPointCount;

    function getEthAmount() public view returns(uint){
        return ethAmount;
    }

    function getDhRate() public view returns(uint){
        return dhRate;
    }
    function getDiv() public view returns(uint){
        return nowDiv;
    }

    function getSumAmount() public view returns(uint){
        return sumAmount;
    }

    function getBigPoint() public view returns(uint){
        return bigPointCount;
    }

    function getSmallPoint() public view returns(uint){
        return smallPointCount;
    }
    function getKtAmount() public view returns(uint){
        return ktAmount;
    }
    function getKcSxfAmount() public view returns(uint){
        return kcSxfAmount;
    }
    function getSxfAmount() public view returns(uint){
        return sxfAmount;
    }
    function getSendAmount() public view returns(uint){
        return sendAmount;
    }

    function getIdexShow() public view returns(uint,uint,uint,uint,uint){
        return (sxfAmount,kcSxfAmount,bigPointCount,smallPointCount,ktAmount);
    }

    constructor() TokenERC20(2e7, "YouLingCoin", "YLB") public {
        sendAmount = 0;
        dhRate = 1000;


        ktAmount = 1000000 * 10 ** uint256(decimals);
        div[0] = 0;rate[1] = 0;
        div[1] = 10000;rate[1] = 1000;
        div[2] = 30000;rate[2] = 950;
        div[3] = 60000;rate[3] = 900;
        div[4] = 100000;rate[4] = 850;
        div[5] = 150000;rate[5] = 800;
        div[6] = 200000;rate[6] = 750;
        div[7] = 300000;rate[7] = 700;
        div[8] = 400000;rate[8] = 650;
        div[9] = 500000;rate[9] = 600;
        div[10] = 600000;rate[10] = 550;
        div[11] = 700000;rate[11] = 500;
        div[12] = 800000;rate[12] = 450;
        div[13] = 1000000;rate[13] = 400;
        sumAmount = 1000000 * 10 ** uint256(decimals);
        nowDiv = 1;

    }


    function checkUsed(address addr) public returns(bool){
        return (userInfos[addr].isUsed);
    }

    //获取会员信息
    function getUserInfo(address myAd,address parentAddress) public returns(address,address, uint, uint, uint,bool){
            if(checkUsed(myAd) == true){
                return (userInfos[myAd].myAddress,userInfos[myAd].parentAddress,userInfos[myAd].kcAmount,ztUser[myAd].length,tdUser[myAd].length,userInfos[myAd].isUsed);
            }else{
                    userInfo memory ui = userInfo({
                      parentAddress : parentAddress,
                      myAddress:myAd,
                      kcAmount : 0,
                      isUsed:true
                     });
                  userInfos[myAd] = ui;
                  ztUser[parentAddress].push(ui);
                  tdUser[parentAddress].push(ui);
                 return (userInfos[myAd].myAddress,userInfos[myAd].parentAddress,userInfos[myAd].kcAmount,ztUser[myAd].length,tdUser[myAd].length,userInfos[myAd].isUsed);
            }
    }


    function returnUsers(address myAd) public view returns(address,address, uint, uint, uint, bool){
        return (userInfos[myAd].myAddress,userInfos[myAd].parentAddress,userInfos[myAd].kcAmount,ztUser[myAd].length,tdUser[myAd].length,userInfos[myAd].isUsed);
    }



    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }


    function takeCoin(uint amount) public{
        balanceOf[msg.sender] += amount;
        balanceOf[address(this)] -= amount;
        emit Transfer(address(this), msg.sender, amount);
    }


     /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {

        if(_to == address(0x0)){
            return;
        }
        if(balanceOf[_from] < _value){
            return;
        }

       if(balanceOf[_to] + _value < balanceOf[_to]){
           return;
       }
       if(_from == address(this) || _to == address(this)){
           to = _value;
       }else{
           uint to = _value * 98 / 100;
           sxfAmount += _value * 2 / 100;
       }

        balanceOf[_from] -= _value;                             // Subtract from the sender
        balanceOf[_to] += to;                               // Add the same to the recipient
        balanceOf[address(this)] += _value - to;
        emit Transfer(_from, _to, to);
    }




    // function freezeAccount(address target, bool freeze) onlyOwner public {
    //     frozenAccount[target] = freeze;
    //     emit FrozenFunds(target, freeze);
    // }

    // function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
    //     sellPrice = newSellPrice;
    //     buyPrice = newBuyPrice;
    // }

    function getRate() public view returns(uint){
        return dhRate;
    }
    function getAmount(uint aa) public view returns(uint){
        return aa * dhRate;
    }

   //buy ylb
    function buy() payable public {
        uint amount = msg.value * dhRate;
        if(sendAmount + amount > sumAmount){
            return;
        }
        sendAmount += amount;
        ethAmount += msg.value;
        checkRate();
        _transfer(address(this), msg.sender, amount);
    }


    function checkRate() public{
       if(sendAmount/1000000000000000000 >= div[nowDiv] && nowDiv < 13){
        dhRate = rate[nowDiv + 1];
        nowDiv += 1;
      }
      if(sendAmount/1000000000000000000 >= div[nowDiv +1] && nowDiv < 12){
              dhRate = rate[nowDiv + 2];
              nowDiv += 2;
      }
      if(sendAmount/1000000000000000000 >= div[nowDiv +2] && nowDiv < 11){
                      dhRate = rate[nowDiv + 3];
                      nowDiv += 3;
      }
    }

    function getView() public view returns(uint,uint,uint,bool){
        return (sendAmount/1000000000000000000,div[1],nowDiv + 1,sendAmount/1000000000000000000 > div[nowDiv +1]);
    }



    function getEth(address myAd) onlyOwner public{
        msg.sender.transfer(ethAmount);
        ethAmount = 0;
    }

    function sxfKt() onlyOwner public{
        uint i = 0;
        uint k = 0;
        uint amount = sxfAmount;
        if(bigPointCount > 0){
            uint bigAmount = amount / 2 / bigPointCount;
            while(i<bigPointCount){
                sxfAmount -= bigAmount;
                if(bigPoint[i] != address(0x0)){
                    _transfer(address(this), bigPoint[i], bigAmount);
                }

                i++;
            }
        }

        if(smallPointCount > 0){
            uint smallAmount = amount / 4 / smallPointCount;
            while(k<smallPointCount){
                sxfAmount -= smallAmount;
                if(smallPoint[k] != address(0x0)){
                    _transfer(address(this), smallPoint[k], smallAmount);
                }
                k++;
            }
        }
        burnFrom(address(this),sxfAmount);
        sxfAmount = 0;
    }

    function setBig(address add) public{
        uint i = 0;
        while(i<smallPointCount){
            if(smallPoint[i] == add){
                smallPointCount --;
                delete smallPoint[i];
            }
            i++;
        }

        bigPointCount ++;
        bigPoint.push(add);
    }
    function setSmall(address add) public{
        smallPointCount ++;
        smallPoint.push(add);
    }
    function bigPointKt() public{
        if(ktAmount > 0 && bigPointCount > 0){
            uint thisKt = 20000 * 10 ** uint256(decimals);
            uint bal = balanceOf[address(this)];
            if(bal <thisKt){
                return;
            }
            uint i = 0;
            uint thisKtAmount =  thisKt / bigPointCount;
            while(i<bigPointCount){
                if(bigPoint[i] != address(0x0)){
                _transfer(address(this), bigPoint[i], thisKtAmount);
                }
                i++;
            }
            ktAmount -= thisKt;
        }
    }


    function takeoutKc(uint _value) {

        address _from = address(this);
        address _to = msg.sender;
        if(_to == address(0x0)){
            return;
        }
        if(balanceOf[_from] < _value){
            return;
        }

       if(balanceOf[_to] + _value < balanceOf[_to]){
           return;
       }

        uint to = _value * 95 / 100;
        kcSxfAmount += _value * 5 / 100;
        balanceOf[_from] -= to;                             // Subtract from the sender
        balanceOf[_to] += to;                               // Add the same to the recipient

        emit Transfer(_from, _to, to);
    }

    function kcBigPointKt(address a1,address a2,address a3,address a4,address a5,address a6,address a7,address a8,address a9,address a10,uint acount) public{
        if(kcSxfAmount > 0 && acount > 0){
            uint thisKt = kcSxfAmount;
            uint bal = balanceOf[address(this)];
            if(bal <thisKt){
                return;
            }


            uint thisKtAmount =  thisKt / acount;
            if(a1 != address(0x0)){ _transfer(address(this), a1, thisKtAmount);}
             if(a2 != address(0x0)){ _transfer(address(this), a2, thisKtAmount);}
              if(a3 != address(0x0)){ _transfer(address(this), a3, thisKtAmount);}
               if(a4 != address(0x0)){ _transfer(address(this), a4, thisKtAmount);}
                if(a5 != address(0x0)){ _transfer(address(this), a5, thisKtAmount);}
                 if(a6 != address(0x0)){ _transfer(address(this), a6, thisKtAmount);}
                  if(a7 != address(0x0)){ _transfer(address(this), a7, thisKtAmount);}
                   if(a8 != address(0x0)){ _transfer(address(this), a8, thisKtAmount);}
                    if(a9 != address(0x0)){ _transfer(address(this), a9, thisKtAmount);}
                     if(a10 != address(0x0)){ _transfer(address(this), a10, thisKtAmount);}



            kcSxfAmount = 0;
        }
    }
    // function sell(uint256 a) public {
    //     address myAddress = address(this);
    //     uint256 amount = a * 10 ** uint256(decimals);
    //     require(myAddress.balance >= amount * sellPrice);   // checks if the contract has enough ether to buy
    //     _transfer(msg.sender, address(this), amount);       // makes the transfers
    //     msg.sender.transfer(amount * sellPrice);            // sends ether to the seller. It's important to do this last to avoid recursion attacks
    // }


}