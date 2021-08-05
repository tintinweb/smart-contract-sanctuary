// SPDX-License-Identifier: UNLISCENSED

pragma solidity 0.8.4;

import "./utils.sol";

contract SWP {
    
    using SafeMath for uint256;
    
    address constant PK_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // TestNet
    //address constant PK_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    //address constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // TestNet
    //address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // MainNet
    //address constant BUSD = 0xe9e7cea3dedca5984780bafc599bd69add087d56; // MainNet
    address constant USDC = 0x9780881Bf45B83Ee028c4c1De7e0C168dF8e9eEF; // TestNet
    address constant BUSD = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee; // TestNet

    address constant BASE = BUSD;

    
    string  public  name = "Solindex";
    string  public  symbol = "SOL";
    string  constant  version = "0.2.0";
    uint256 constant initialShares = 1000000000000000000; // 10^18
    uint256 constant MAXINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint8   constant decimals = 18;
    uint256 constant SLIPPAGE = 90;

    uint256 public  totalSupply = 0; // 10^18

    struct Trade {
        uint256 amount_to_trade;
        address token_to_trade;
    }

    // These are public for debugging
    uint16  public w;
    uint256 public price;
    uint256 public delta;
    uint256 public H;
    uint256 public K;
    uint16  public total;
    uint256 public aum;

    
    address private owner;
    address[] public assets;
    
    mapping(address => uint ) public holdings; // position in `assets`
    mapping(address => uint16) public weights;  // percentage weights of assets
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor (
        string memory _name, 
        address[] memory _tokens,
        uint8[] memory _weights
        ) {
        name = _name;
        balanceOf[msg.sender] = 0;
        owner = msg.sender;
        
        for (uint i=0; i<_tokens.length; i++) {
            addAsset(_tokens[i]);
            setWeightForToken(_tokens[i], _weights[i]);
        }
        
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }
    
    modifier onlyOwnerOrSelf() {
        require(owner == msg.sender || address(this) == msg.sender, "Caller is not the owner nor the contract itself");
        _;
    }


    // Standard transfer functions
    
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
    
    
    // Invest and disinvest
    
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED DC');
    }
    
    function investAndTest(uint256 _bnb) public returns (bool success) {
        // Need to approve manually first

        uint256 share = 0;
    
        // Create shares
        if (AUM()>0) {
            share = _bnb.mul(totalSupply).div(AUM());
        } else {
            share = initialShares;
        }
        
        // Transfer BASE
        safeTransferFrom(BASE, msg.sender, address(this), _bnb);

        // Distribute shares
        totalSupply = totalSupply.add(share);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(share);


        /// TEST stuffs
            
        address[] memory path    = new address[](2);
        path[0] = BASE;
        
        // Buy some `DAI` and set weight to 40 %
        path[1] = 0xEC5dCb5Dbf4B114C9d0F65BcCAb49EC54F6A0867;
        buyToken(path, 5000000000000000);
        addAsset(path[1]);
        setWeightForToken(path[1], 40);
        
        // Buy some `token0` and set weight to 45 %
        path[1] = 0x4F5DA48704F6D9d7DF7650DB7219e1c647Fd5F87;
        buyToken(path, 3000000000000000);
        addAsset(path[1]);
        setWeightForToken(path[1], 45);
        
        // Rebalance
        rebalanceFromOutside();
        
    
        return true;
    }
    
    function invest(uint256 _bnb) public returns (bool success) {
        // Need to approve manually first

        uint256 share = 0;
    
        // Create shares
        if (AUM()>0) {
            share = _bnb.mul(totalSupply).div(AUM());
        } else {
            share = initialShares;
        }
        
        // Transfer BASE
        safeTransferFrom(BASE, msg.sender, address(this), _bnb);

        // Distribute shares
        totalSupply = totalSupply.add(share);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(share);
    
        return true;
    }
    
    function disinvest(uint256 _swp) public returns (bool success) {
        
        require(balanceOf[msg.sender] >= _swp);

        // Calculate BASE amount
        uint256 _bnb = _swp.mul(AUM()).div(totalSupply);
        
        if (_bnb > CASH()) {
            aum = AUM().sub(_bnb);
            rebalance(aum);
        }
        
        // Transfer BASE
        safeTransferFrom(BASE, address(this), msg.sender, _bnb);

        // Burn shares
        balanceOf[msg.sender] -= _swp;
        totalSupply -= _swp;

        return true;
        

        // OLD STUFFS
        // while (_bnb > CASH()) {
        //    address[] memory path = new address[](2);
        //    path[1] = BASE;
        //    path[0] = assets[assets.length - 1]; // Sell the last token from `assets` 
        //    sellTokenAll(path);                  // This removes the last token from `assets`
        //    _bnb = _swp.mul(AUM()).div(totalSupply);
        //}
   
    }
    
    
    // Owner's functions to trade 
    
    function approvePancake(address _token) private returns (bool _success) { 
        
        if (ERC20(_token).allowance(address(this), PK_ROUTER) < MAXINT.div(10)) {
            return ERC20(_token).approve(PK_ROUTER, MAXINT);
        } else {
            return true;
        }
    }

    function addAsset(address _token) private {
        assets.push(_token);
        holdings[_token] = assets.length-1;
    }

    function removeAsset(address _token) private {
        uint index = holdings[_token];
        assets[index] = assets[assets.length - 1]; // Move the last element into the place to delete
        assets.pop(); // Remove the last element
        if (assets.length>0) {
            holdings[assets[index]] = index; // keep track of the indices correctly
        }
    }
    
    function buyToken(address[] memory path, uint256 _bnb) private returns (bool _success) {
        
        approvePancake(BASE);
        //uint256 owned = ERC20(path[1]).balanceOf(address(this));
        uint256 amount = PK(PK_ROUTER).getAmountsOut(_bnb, path)[1];
        amount = amount.mul(100-SLIPPAGE).div(100); // amountOutMin
        PK(PK_ROUTER).swapExactTokensForTokens( _bnb, amount, path, address(this), block.timestamp + 60 );
        // if (owned==0) { addAsset(path[1]); } // Record new position
        return true;
        
    }
    
    function sellToken(address[] memory path, uint256 _amount) private returns (bool _success) {
        
        approvePancake(path[0]);
        uint256 owned = ERC20(path[0]).balanceOf(address(this));
        uint256 amount = PK(PK_ROUTER).getAmountsOut(_amount, path)[1];
        amount = amount.mul(100-SLIPPAGE).div(100); // amountOutMin
        PK(PK_ROUTER).swapExactTokensForTokens( _amount, amount, path, address(this), block.timestamp + 60 );
        if ( owned <= _amount ) { removeAsset(path[0]); } // Delete the old position
        return true;
    }

    function sellTokenAll(address[] memory path) private returns (bool _success) {
        approvePancake(path[0]);
        uint256 balance = ERC20(path[0]).balanceOf(address(this));
        uint256 amount = PK(PK_ROUTER).getAmountsOut(balance, path)[1];
        amount = amount.mul(100-SLIPPAGE).div(100); // amountOutMin
        PK(PK_ROUTER).swapExactTokensForTokens( balance, amount, path, address(this), block.timestamp + 60 );
        removeAsset(path[0]); // Delete the old position
        return true;
    }


    // Owner's functions to set weights
    
    function checkWeights() private returns (bool _success) { 
        total = 0;
        for (uint i=0; i<assets.length; i++) {
            total += weights[assets[i]];
        }
        require(total <= 100, "Sum of weights exceeds 100 %");
        weights[BASE] = 100 - total;
        return true;
    }
    
    function setWeightForToken(address _token, uint8 _weight) public onlyOwnerOrSelf returns (bool _success) { 
        weights[_token] = _weight;
        checkWeights();
        return true;
    }
    
    
    // Views
    
    function M2M() public view returns (uint256 _m2m) {
        uint256 m2m = 0;
        uint256 amount;
        address[] memory path    = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        
        path[1] = BASE;
        
        for (uint i=0; i<assets.length; i++) {
            path[0] = assets[i];
            amount  = ERC20(assets[i]).balanceOf(address(this));
            if (amount > 0 ) {
                amounts = PK(PK_ROUTER).getAmountsOut(amount, path);
                m2m = m2m.add(amounts[1]);       
            }
        }
        return m2m;
    }
    
    function AUM() public view returns (uint256 amount) {
        return CASH().add(M2M());
    }
    
    function CASH() public view returns (uint256 amount) {
        return ERC20(BASE).balanceOf(address(this));
    }
    
    function SharePrice() public view returns (uint256 _price) {
        return AUM().mul(initialShares).div(totalSupply);
    }
    
    function Weight(address _token) public view returns (uint256 _weight) {
        if (_token==BASE) {
            return CASH().mul(initialShares).div(AUM());    
        } else {
            address[] memory path = new address[](2);
            path[0] = _token;
            path[1] = BASE;
            uint256 amount  = ERC20(_token).balanceOf(address(this));
            amount = PK(PK_ROUTER).getAmountsOut(amount, path)[1];
            return amount.mul(initialShares).div(AUM());    
        }
        
    }
    
    function desiredHoldings(uint256 _AUM, uint16 _w, uint256 _amount0, uint256 _amount1) pure private returns (uint256 _desired) {
        return _AUM.mul(_w).div(100).mul(_amount0).div(_amount1);   
    }
 
     // Re-balancing
    function rebalance(uint256 _AUM) private returns (bool _success) {
        uint b = 0;
        uint s = 0;
        uint256 amount;
        address[] memory path    = new address[](2);
        uint256[] memory amounts = new uint256[](2); 
     
        Trade[] memory to_buy  = new Trade[](assets.length);
        Trade[] memory to_sell = new Trade[](assets.length); 
        
        for (uint i=0; i<assets.length; i++) {
            path[0] = assets[i];
            path[1] = BASE;
            
            if (_AUM==0) {
                aum = s;
                //return true;
                to_sell[s].token_to_trade  = assets[i]; 
                to_sell[s].amount_to_trade = ERC20(assets[i]).balanceOf(address(this));
                s++;
            } else {
            
                w = weights[assets[i]];
                
                amount  = ERC20(assets[i]).balanceOf(address(this)); // Current holdings of token i
                K = amount;
                
                amounts = PK(PK_ROUTER).getAmountsOut(1000, path);
                H = desiredHoldings(_AUM, w, amounts[0], amounts[1]);  // Desired holdings of token i
                
                // Compute quantities to buy or sell
                if (amount > H) {
                    delta = amount - H; // should sell quantity `delta` (in units of the token)
                    if (delta.mul(amounts[1]).div(amounts[0]).mul(initialShares).div(_AUM) > initialShares.mul(5).div(100) )
                    {
                        to_sell[s].token_to_trade  = assets[i]; 
                        to_sell[s].amount_to_trade = delta;
                        s++;
                    }
                } else {
                    delta = H - amount; // should buy quantity `delta` (in units of the token)
                    delta = delta.mul(amounts[1]).div(amounts[0]); // (in units of BASE)
                    if (delta.mul(initialShares).div(_AUM) > initialShares.mul(5).div(100) ) {
                        to_buy[b].token_to_trade  = assets[i];
                        to_buy[b].amount_to_trade = delta;
                        b++;                    
                    }
    
                }
                
            }
            
            
        }
        
        
        // Now first sell stuffs...
        path[1] = BASE;
        for (uint i=0; i<s; i++) {
            path[0] = to_sell[i].token_to_trade;
            sellToken(path, to_sell[i].amount_to_trade);
        }
        
        // ...and then buy stuffs
        path[0] = BASE;
        for (uint i=0; i<b; i++) {
            path[1] = to_buy[i].token_to_trade;
            buyToken(path, to_buy[i].amount_to_trade);
        }
        
        
        return true;
    }
    
    function rebalanceFromOutside() public returns (bool _success) {
        return rebalance(AUM());
    }
    
}




// 0x095ea7b3 approve(address,uint256)
// 0xd06ca61f getAmountsOut(uint256,address[])    
// 0x38ed1739 swapExactTokensForTokens
// 0xf7639be3 swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256,address[])