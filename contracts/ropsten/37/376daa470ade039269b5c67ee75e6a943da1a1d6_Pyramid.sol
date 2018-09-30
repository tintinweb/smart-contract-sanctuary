pragma solidity ^0.4.18;

contract Pyramid{
    using SafeMath for uint256;
    //DATASETS
    string public name = "Pymarid";
    uint256 public tokenPrice = 0.01 ether;
    uint256 public mintax = 3e15; // about 1 USD
    uint16[3] internal Gate = [11, 101, 1001];
    uint8[4] internal Fee = [1, 2, 3, 4];
    uint256 public totalTokenSupply;
    uint256 public newPlayerFee=0.1 ether;
    uint256 internal administratorMoney;
    uint256 internal FN;
    bool internal isReinvestEnable=false;
    mapping(bytes32 => bool) public administrators;  // type of byte32, keccak256 of address
    mapping(address=>uint256) public tokenBalance;
    mapping(address=>address) public highlevel;
    mapping(address=>address) public rightbrother;
    mapping(address=>address) public leftchild;
    mapping(address=>uint256) public coefficient;
    mapping(address=>uint256) public sellableETH;


    //CONSTRUCTION FUNCTION
    constructor() public{
        administrators[0x4e17695e29d9c1bfa2f4ce16057f4922043ef4952a2cfbea85d3429b5e6fc4df] = true;
        
    }
    //modifier
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[keccak256(_customerAddress)]);
        _;
    }
    modifier onlyBagholders() {
        require(tokenBalance[msg.sender] > 0);
        _;
    }
    //PUBLIC FUNCTION
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        PurchaseTokens(msg.value, _referredBy);
    }
    
    function reinvest(uint256 reinvestAmount)
    onlyBagholders()
    public
    {
        require(isReinvestEnable==true,"This function is not enabled now");
        require(reinvestAmount>1,"At least 1 Token!");
        address _customerAddress = msg.sender;
        require(getReinvestableTokenAmount(_customerAddress)>=reinvestAmount,"You have not enough ETH!");
        uint256 tokens = PurchaseTokens(reinvestAmount.mul(tokenPrice), highlevel[_customerAddress]);
        if(tokens.mul(tokenPrice)<sellableETH[_customerAddress])
        {
            sellableETH[_customerAddress] -= tokens*tokenPrice;
        }
        else
        {
            uint256 eth_lack = tokens.mul(tokenPrice).sub(sellableETH[_customerAddress]).mul(10) / 3;
            coefficient[_customerAddress] = coefficient[_customerAddress].add(eth_lack / tokenBalance[_customerAddress]);
            sellableETH[_customerAddress] = 0;
        }
        
        ///////////////////
        emit onReinvestment(_customerAddress,reinvestAmount,tokens);
    }
    
    //EVENT
    event onEthSell(
        address indexed customerAddress,
        uint256 ethereumEarned
    );
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );
    
    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );
    event testOutput(
        uint256 ret
    );
    event taxOutput(
        uint256 tax,
        uint256 sumoftax
    );
    function withdraw(uint256 _amountOfEths)
    public
    onlyBagholders()
    {
        address _customerAddress=msg.sender;
        uint256 interest = SafeMath.mul(FN.sub(coefficient[_customerAddress])/10, 3*tokenBalance[_customerAddress]);
        uint256 eth_all = sellableETH[_customerAddress].add(interest);
        require(eth_all >= _amountOfEths);
        if(_amountOfEths > sellableETH[_customerAddress]){
            uint256 eth_lack = _amountOfEths.sub(sellableETH[_customerAddress]).mul(10) / 3;
            coefficient[_customerAddress] = coefficient[_customerAddress].add(eth_lack / tokenBalance[_customerAddress]);
            sellableETH[_customerAddress] = 0;
        }
        else{
            sellableETH[_customerAddress] = sellableETH[_customerAddress].sub(_amountOfEths);
        }
        
        _customerAddress.transfer(_amountOfEths);
        emit onEthSell(_customerAddress,_amountOfEths);
        
        //sell logic here
    }
    
    function getReinvestableTokenAmount(address _customerAddress)
    public
    view
    returns(uint256)
    {
        uint256 avaliableETH=getwithdrawableAmount(_customerAddress);
        uint256 maxToken=avaliableETH.div(tokenPrice);
        return maxToken;
    }
    
    function getwithdrawableAmount(address _customerAddress)
    public
    view
    returns(uint256)
    {
        
        return sellableETH[_customerAddress].add(FN.sub(coefficient[_customerAddress]).mul(tokenBalance[_customerAddress])/10*3);
    }
    
    function getTokenBalance()
        public
        view
        returns(uint256)
        {
        address _address = msg.sender;
        return tokenBalance[_address];
        }
    function getContractBalance()public view returns (uint) {
        return address(this).balance;//
    }  
    //Only Administrator Functions
    function withdrawAdministratorMoney(uint256 amount)
        public
        onlyAdministrator()
    {
        address administrator = msg.sender;
        require(amount<administratorMoney,"Too much");
        administrator.transfer(amount);
        administratorMoney = administratorMoney.sub(amount);
    }
    function getAdministratorMoney(address who)
        public
        view
        returns(uint256)
    {
        require(administrators[keccak256(who)]);
        return administratorMoney;
    }
    function setAdministrator(bytes32 _identifier, bool _status)
        onlyAdministrator()
        public
    {
        administrators[_identifier] = _status;
    }
    function setName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }
    function setGate(uint _which,uint16 value)
        onlyAdministrator()
        public
    {
        Gate[_which] = value;
    }
    function setFee(uint _level, uint8 value)
    onlyAdministrator()
    public
    {
        Fee[_level] = value;
    }
    function setTokenValue(uint256 _value)
        onlyAdministrator()
        public
    {
        tokenPrice = _value;
    }
    function setnewPlayerFee(uint256 _value)
        onlyAdministrator()
        public
    {
        newPlayerFee=_value;
    }
    function setReinvest(bool _value)
        onlyAdministrator()
        public
    {
        isReinvestEnable=_value;
    }
    
    
    function getFeeRate(address _customerAddress)
    public
    view
    returns(uint8)
    {
        if(tokenBalance[_customerAddress]<1){
            return 0;
        }
        uint8 i;
        for(i=0; i<Gate.length; i++){
            if(tokenBalance[_customerAddress]<Gate[i]){
                break;
            }
        }
        return Fee[i];
    }
    
    // function treeBuild(address _referredBy,address _customer)
    // internal
    // {
    //     require(tokenBalance[_referredBy] > 0);
    //     address mostRightNode;
    //     address temp;
    //     if(leftchild[_referredBy]==0x0000000000000000000000000000000000000000)
    //     {
    //         leftchild[_referredBy] = _customer;
    //     }
    //     else{
    //         temp = leftchild[_referredBy];
    //         while(rightbrother[temp]!=0x0000000000000000000000000000000000000000){
    //             temp = rightbrother[temp];
                
    //         }
    //         mostRightNode=temp;
    //         rightbrother[mostRightNode]=_customer;
    //     }
    // }
     function treeBuild(address _referredBy,address _customer)
    internal
    {
        require(tokenBalance[_referredBy] > 0);
        if(leftchild[_referredBy]!=0x0000000000000000000000000000000000000000)
        {
            rightbrother[_customer] = leftchild[_referredBy];
        }
        leftchild[_referredBy] = _customer;
    }
    function getcoeffcient(address customer,uint256 num)
    internal
    {
        // Approach 1.
        // Use harmonic series to cal player divs. This is a precise algorithm.
        // uint256 temp=FN;
        // uint256 c_temp=coefficient[customer]*tokenBalance[customer];
        // for(uint8 i=1; i<=num; i+=1)
        // {
        //    c_temp += temp;
        //    temp+=tokenPrice/(i+totalTokenSupply);
        // }
        // FN = temp;
        // coefficient[customer] = c_temp / tokenBalance[customer].add(num)
        // totalTokenSupply += num;
        ////////////////////////////////////////////////////////////////////////
        // Approach 2.
        // Simplify the "for loop" of approach 1.
        // You can get more divs than approach 1 when you buy more than 1 token at one time.
        // cal average to avoid overflow.
        uint256 average_before = coefficient[customer].mul(tokenBalance[customer]) / tokenBalance[customer].add(num);
        uint256 average_delta = FN.mul(num) / (num + tokenBalance[customer]);
        coefficient[customer] = average_before.add(average_delta);
        FN = FN.add(tokenPrice.mul(num) / totalTokenSupply.add(num));
        totalTokenSupply += num;
    }
    function PurchaseTokens(uint256 _incomingEthereum, address _referredBy)
        internal
        returns(uint256)
    {   
        /////////////////////////////////
        address _customerAddress=msg.sender;
        uint256 numOfToken;
        require(_referredBy==0x0000000000000000000000000000000000000000 || tokenBalance[_referredBy] > 0);
        if(tokenBalance[_customerAddress] > 0)
        {
            require((_incomingEthereum >tokenPrice) || (_incomingEthereum == tokenPrice),"ETH is NOT enough");
            require(_incomingEthereum % tokenPrice ==0);
            require(highlevel[_customerAddress] == _referredBy);
            numOfToken = ethereumToTokens_(_incomingEthereum);
            tokenBalance[_customerAddress] = numOfToken.add(tokenBalance[_customerAddress]);
        }
        else
        {
            //New player without a inviter will be taxed for 0.1ETH, and this value can be changed by administrator
            if(_referredBy==0x0000000000000000000000000000000000000000 || _referredBy==_customerAddress)
            {
                require(_incomingEthereum >= newPlayerFee+tokenPrice,"ETH is NOT enough");
                require((_incomingEthereum-newPlayerFee) % tokenPrice ==0);
                numOfToken = ethereumToTokens_(_incomingEthereum - newPlayerFee);
                highlevel[_customerAddress] = 0x0000000000000000000000000000000000000000;
                
            }
            else
            {
                // new player with invite address.
                require((_incomingEthereum >tokenPrice) || (_incomingEthereum == tokenPrice),"ETH is NOT enough");
                require(_incomingEthereum % tokenPrice ==0);
                numOfToken = ethereumToTokens_(_incomingEthereum);
                highlevel[_customerAddress] = _referredBy;
                treeBuild(_referredBy,_customerAddress);
            }
            tokenBalance[_customerAddress] = numOfToken;
            sellableETH[_customerAddress] = 0;
        }
        getcoeffcient(_customerAddress,numOfToken);
        taxEth(_incomingEthereum,_customerAddress);
        emit onTokenPurchase(_customerAddress,_incomingEthereum,numOfToken,_referredBy); 
        return numOfToken;
        
    }
    
    function mul_float_power(uint256 x, uint8 n, uint8 numerator, uint8 denominator)
        internal
        returns(uint256)
    {
        uint256 ret = x;
        if(x==0 || numerator==0){
            return 0;
        }
        for(uint8 i=0; i<n; i++){
            ret = ret.mul(numerator).div(denominator);
        }
        emit testOutput(ret);
        return ret;

    }
    
    function taxEth(uint256 _incomingEthereum,address _customerAddress)
        internal 
        returns(uint256)
    {
        address _highlevel=highlevel[_customerAddress];
        uint256 tax;
        uint256 sumOftax=0;
        uint8 i=0;
        uint256 globalfee = _incomingEthereum.mul(3).div(10);
        while(_highlevel!=0x0000000000000000000000000000000000000000&&tokenBalance[_highlevel] > 0)
        {
            
            i++;
            //////////////////////////////////
            tax=mul_float_power(_incomingEthereum, i, getFeeRate(_highlevel), 10);
            if(tax <= mintax){
                break;
            }
            sellableETH[_highlevel] = sellableETH[_highlevel].add(tax);
            sumOftax = sumOftax.add(tax);
            _highlevel = highlevel[_highlevel];
            emit taxOutput(tax,sumOftax);
        }
        
        if(sumOftax.add(globalfee) < _incomingEthereum)
        {
            administratorMoney = _incomingEthereum.sub(sumOftax).sub(globalfee).add(administratorMoney);
        }
        
            
    }
    function ethereumToTokens_(uint256 _ethereum)
        internal
        view
        returns(uint256)
    {
        return _ethereum.div(tokenPrice);
    }
    function tokensToEthereum_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {
        return _tokens.mul(tokenPrice);
    }
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}