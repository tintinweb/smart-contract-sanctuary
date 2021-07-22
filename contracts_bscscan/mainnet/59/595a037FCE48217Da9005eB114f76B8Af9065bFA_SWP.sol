// SPDX-License-Identifier: UNLISCENSED

pragma solidity 0.8.4;

import "utils.sol";

contract SWP {
    
    // address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // TESTNet
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    // address PANCAKE_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // TESTNet
    address PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    using SafeMath for uint256;
    
    string  public  name = "Swapper";
    string  public  symbol = "SWP";
    uint256 public  totalSupply = 0; // 10^18
    uint256 public  initialShares = 1000000000000000000; // 10^18
    uint256 private MAXINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint8   public  decimals = 18;
    
    address private owner;
    address[] public assets;
    mapping(address => mapping(string => uint256)) public holdings; 
    // 'index' --> index, 'tokens' --> # of tokens
    
    function getHoldingsOf(address _token) private view returns (uint256 _holding) {
        return holdings[_token]['tokens'];
    }

    function addAssets(address _token, uint256 _amount) private {

        if (holdings[_token]['tokens']==0) {
            assets.push(_token);
            holdings[_token]['tokens'] = _amount;
            holdings[_token]['index' ] = assets.length-1;
        } else {
            holdings[_token]['tokens'] += _amount;
        }
    }

    function removeAssets(address _token, uint256 _amount) private {

        if (holdings[_token]['tokens']<=_amount) {
            uint index = holdings[_token]['index'];
            assets[index] = assets[assets.length - 1]; // Move the last element into the place to delete
            assets.pop(); // Remove the last element
            holdings[_token]['tokens'] = 0;
        } else {
            holdings[_token]['tokens'] = holdings[_token]['tokens'].sub(_amount);
        }
    }
    
    
    uint256 public CASH  = 0;
    uint256 public M2M   = 0;
    uint256 public AUM   = 0;
    uint256 public PRC   = 0;
    
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    constructor() {
        balanceOf[msg.sender] = 0;
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom( address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to].add(_value);
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED DC');
    }
    
    function invest(uint256 _bnb) public returns (bool success) {
        // Need to approve manually first

        uint256 share = 0;
    
        // Create shares
        if (AUM>0) {
            share = _bnb.mul(totalSupply).div(AUM);
        } else {
            share = initialShares;
        }
        
        // Transfer WBNB
        safeTransferFrom(WBNB, msg.sender, address(this), _bnb);
        computeAUM();

        // Distribute shares
        totalSupply = totalSupply.add(share);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(share);

        return true;
    }
    
    function disinvest(uint256 _swp) public returns (bool success) {
        
        require(balanceOf[msg.sender] >= _swp);

        // Calculate WBNB amount
        uint256 _bnb = _swp.mul(AUM).div(totalSupply);

        // TO-DO: Better handle the case in which not enough WBNB are available
        // Currently, it just sells the entire holdings of each token, 
        // starting from the one purchased most recently, 
        // until the CASH amount is laerge enough to over the outflow
        uint i = 0;
        while (_bnb > CASH) {
            sellTokenAll(assets[assets.length - i]);
            i ++;
        }

        // Transfer WBNB
        safeTransferFrom(WBNB, address(this), msg.sender, _bnb);

        // Burn shares
        balanceOf[msg.sender] -= _swp;
        totalSupply -= _swp;

        // Update AUM and CASH
        computeAUM();
        return true;
   
    }
    
    function approvePancake(address _token) private onlyOwner returns (bool _success) { 
        
        uint256 allowed = ERC20(_token).allowance(address(this), PANCAKE_ROUTER);
        
        if (allowed < MAXINT.div(2)) {
            return ERC20(_token).approve(PANCAKE_ROUTER, MAXINT);
        } else {
            return true;
        }
    }

    function buyToken(address _token, uint256 _bnb) public onlyOwner returns (bool _success) {
        
        approvePancake(WBNB);
        
        uint256 SLIPPAGE = 90;
        address[] memory path = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        path[0] = WBNB;
        path[1] = _token;
        
        amounts = PK(PANCAKE_ROUTER).getAmountsOut(_bnb, path);
        uint256 amountOutMin = amounts[1].mul(100-SLIPPAGE).div(100);
        
        amounts = PK(PANCAKE_ROUTER).swapExactTokensForTokens(
            _bnb,
            amountOutMin,
            path,
            address(this),
            block.timestamp + 2 days
        );
        computeAUM();
        addAssets(_token, amounts[1]);
        return true;
        
    }
    
    function sellToken(address _token, uint256 _amount) public onlyOwner returns (bool _success) {
        // Need to approve before this

        uint256 SLIPPAGE = 90;
        address[] memory path = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        path[0] = _token;
        path[1] = WBNB;
        
        
        amounts = PK(PANCAKE_ROUTER).getAmountsOut(_amount, path);
        uint256 amountOutMin = amounts[1].mul(100-SLIPPAGE).div(100);
        
        amounts = PK(PANCAKE_ROUTER).swapExactTokensForTokens(
            _amount, amountOutMin, path, address(this), block.timestamp + 2 days
        );
        
        //uint256[] memory amounts = abi.decode(data2, (uint256[]));
        computeAUM();

        // Delete the old position
        removeAssets(_token, _amount);

        return true;
    
    }

    function sellTokenAll(address _token) public onlyOwner returns (bool _success) {
        approvePancake(_token);
        uint256 balance = ERC20(_token).balanceOf(address(this));
        return sellToken(_token, balance);
    }
    
    function getM2M() public view returns (uint256 _m2m) {
        uint256 m2m = 0;
        address[] memory path    = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        
        path[1] = WBNB;
        
        for (uint i=0; i<assets.length; i++) {
            path[0] = assets[i];
            amounts = PK(PANCAKE_ROUTER).getAmountsOut(holdings[assets[i]]['tokens'], path);
            m2m = m2m.add(amounts[1]);       
        }
        return m2m;
    }
    
    function getAUM() public view returns (uint256 amount) {
        return ERC20(WBNB).balanceOf(address(this)).add(getM2M());
    }
    
    function computeAUM() private returns (bool _success) {
        CASH = ERC20(WBNB).balanceOf(address(this));
        M2M = getM2M();      // Computes mark-to-market value
        AUM = CASH.add(M2M); // in WBNB
        return true;
    }
    
    function getSharePrice() public view returns (uint256 _price) {
        return getAUM().mul(initialShares).div(totalSupply);
    }
    
    function getMarketCap() public view returns (uint256 _value) {
        return getSharePrice().mul(totalSupply).div(initialShares);
    }

    
    
}




// 0x095ea7b3 approve(address,uint256)
// 0xd06ca61f getAmountsOut(uint256,address[])    
// 0x38ed1739 swapExactTokensForTokens
// 0xf7639be3 swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256,address[])