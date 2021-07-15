/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

//https://pad.riseup.net/p/.-tmp
interface IRouter{
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline)external returns (uint[] memory amounts);
}
contract BitcoinBack{
    uint8 public decimals=18;
    string public name='BitcoinBack';//name
    string public symbol='BB';//ticker symbol
    mapping(address=>uint256) public balances;//normal balances
    mapping(address=>uint256) public lastClaim;//last totalClaimed value
    uint256 public totalClaimed;
    uint256 public lastPayoutAmount;//token amount
    uint256 public lastPayoutTime;//payout time
    mapping(address=>bool)public whitelist;//whitelisted from fees for swap
    address public owner;//Renounce
    address public marketingWallet;//marketing team
    bool public taxEnabled;//taxes
    uint256 public _totalSupply=21000000;//21 Million
    mapping(address=>mapping(address=>uint256)) public allowance;//allowance
    IRouter public router;//pancake router
    constructor(){
        owner=msg.sender;
        lastPayoutTime=block.timestamp;
        marketingWallet=msg.sender;
        router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        balances[msg.sender]=_totalSupply;//give  _totalSupply to sender
        whitelist[msg.sender]=true;//
        whitelist[marketingWallet]=true;
    }
    function renounce()external{
        _claim(address(msg.sender));
        if(address(msg.sender)==owner){
            whitelist[msg.sender]=false;//remove the tax-exempt whitelist
            taxEnabled=true;
        }

    }
    function exempt(address addy)external{
        require(address(msg.sender)==owner);
        whitelist[addy]=true;
    }
    function changeMarketingWallet(address addy)external{
        _claim(marketingWallet);
        if(address(msg.sender)==owner){
            marketingWallet=addy;
        }
    }
    function bonusOf(address addy)public view returns (uint ret){
        uint256 bonus;
        if(taxEnabled==true){
            if(lastClaim[addy]<totalClaimed){
                bonus=(totalClaimed-lastClaim[msg.sender])*
                (balances[addy]/_totalSupply);
            }
            //if overflow occurred
            else{
                if(lastClaim[addy]!=0){
                    bonus+=(115792089237316195423570985008687907853269984665640564039457584007913129639935-lastClaim[addy])*balances[addy]/_totalSupply;
                }
                bonus+=totalClaimed*balances[addy]/_totalSupply;
            }
        }
        return bonus;
    }
    function claim()external{
        _claim(address(msg.sender));
    }
    function _claim(address addy)public{
        uint256 bonus= bonusOf(addy);
        if(bonus!=0){
            allowance[address(this)][0x10ED43C718714eb63d5aA57B78B54704E256024E]=bonus;
            //balances[addy]+= bonus;//reflect
            address [] memory path=new address[](2);//(2)defines array length
            path[0]=address(this);
            path[1]=0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
            /*address(0x10ED43C718714eb63d5aA57B78B54704E256024E).call(abi.encodeWithSignature(
                "swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)",
                bonus,0,path,addy,block.timestamp
            ));*/
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(bonus,0,path,addy,block.timestamp);
            balances[address(this)]-=bonus;
            totalClaimed+=bonus;
        }
        lastClaim[msg.sender]=totalClaimed;
    }
    function balanceOf(address addy) view public returns (uint ret){
        return balances[addy]+bonusOf(addy);
    }
    function transfer(address receiver,uint256 amount)external returns(bool){
        _transfer(msg.sender,receiver,amount);
        return true;
    }
    function transferFrom(address sender, address receiver,uint256 amount)external returns(bool){
        require(balances[sender]>=amount);
        require(allowance[sender][receiver]>=amount);
        _transfer(sender,receiver,amount);
        allowance[sender][receiver]-=amount;
        return true;
    }
    function _transfer(address sender, address receiver,uint256 amount)internal{
        require(balances[sender]>=amount);
        _claim(sender);//claim for both users and update their balances
        _claim(receiver);
        uint256 tax;
        if(taxEnabled==true&&whitelist[sender]==false){
            tax = amount *89/100;//10% to btc conversion + 1% to marketingWallet = 11% tax
        }
        balances[sender]-=amount;//remove total sent from msg.sender
        balances[receiver]+=amount-tax;//send to receiver
        totalClaimed+=tax*10/11;//reflect
        balances[address(this)]+=tax*10/11;//update balance of reflect bonuses
        balances[marketingWallet]+=tax-(tax*10/11);//marketing tax
    }
    function approve(address spender, uint256 amount)external{
        allowance[msg.sender][spender]=amount;
        _claim(msg.sender);//claim for both users and update their balances
        _claim(spender);
    }
}