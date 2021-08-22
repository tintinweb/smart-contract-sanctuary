// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract LKSCTest is Context, ERC20 {

    constructor () ERC20("LKSCOIN test", "LKSCt") {
        _mint(_msgSender(), 10000000000000 * (10 ** uint256(decimals())));
    }
}

// eliminare la parte che riguarda LKS e aggiungere gli eventi

contract TokenStaking {
    
    using SafeMath for uint256;

    IERC20 private _token;
    uint256 private _startRewards = 0; // data di start e relativa data di stop (gestito da owner)
    uint256 private _stopRewards;
    uint256 private _totalRewardAmount = 0; //totale delle reward da pagare nel periodo (gestito da Owner)
    uint256 private _totalStackedAmount;
    uint256 private _deployTimeStamp;
    mapping(address => uint256) private _usersAmount; // cambia con gli updates da parte dell'utente
    mapping(address => uint256) private _userLastUpdate; // verrà inserito il timestamp dell'ultimo update da parte dell'utente
    mapping(address => uint256) private _userStakedAmount; // verranno inseriti: gli importi inviati al contratto, gli importi ricevuti come rewards e sottratti i withdraw.
    
    // manager
    address private manager;
    
    // events
    event Stake(
        address indexed sender, 
        uint256 amount, 
        uint256 timestamp
    );
    
    event Withdraw(
        address indexed sender, 
        uint256 amount, 
        uint256 timestamp
    );
    
    event UpdateRewards(
        address indexed sender, 
        uint256 amount, 
        uint256 timestamp
    );
    
    constructor (IERC20 token){
        _token = token;
        _deployTimeStamp = block.timestamp;
        manager = msg.sender;
    }

    
    /* ----- SEZIONE SCRITTURA UTENTE ----- */
    /* funzione che fa fare uno staking all'utente */
    function stake(uint256 amount) external updateRewards(msg.sender){ // aggiungere anche l'eventuale update di rewards 
        require(_startRewards > _deployTimeStamp, "liquidity is not started");
        require(_stopRewards > block.timestamp, "liquidity is finish");
        address from = msg.sender;
        uint256 time = block.timestamp;
        _token.allowance(from,  address(this));
        require(_token.transferFrom(from, address(this), amount), "Error during staking");
        
        _usersAmount[from] += amount;
        _userStakedAmount[from] += amount;
        _userLastUpdate[from] = time;
        _totalStackedAmount += amount;
        
        emit Stake(from, amount, time);
    }
    
     /* funzione che fa fare un withdraw all'utente */
    function withdraw(uint256 amount) external updateRewards(msg.sender){
        require(_usersAmount[msg.sender] >= amount, "Request amount over balance");
        address from = msg.sender;
        uint256 time = block.timestamp;
        _usersAmount[from] -= amount;
        _userStakedAmount[from] -= amount;
        _userLastUpdate[from] = time;
        _totalStackedAmount -= amount;
        
        _token.transfer(msg.sender, amount);
        
        emit Withdraw(from, amount, time);
    }
    
    
    /* ----- SEZIONE MANAGER ----- */
    /* Funzione MANAGER cambia l'importo di rewards -da usare come prima opzione dopo aver creato il contratto - */
    function setTotalRewardAmount(uint256 amount) external onlyOwner returns(bool){ // onlyOwner
        _totalRewardAmount = amount;
        return true;
    }
    
    /* funzione MANAGER che serve a far partire il contratto di staking */
    function startRewards() external onlyOwner{ // onlyOwner
        require(_totalRewardAmount >= 1000000000000000000, "Minimum Reward Amount 1 * 10 ** 18 Token");
        _startRewards = block.timestamp;
        _stopRewards = _startRewards + 10 days; //365
    }
    
    /* funzione MANAGER per recuperare i resti che rimarranno dentro al contratto */
    function withdrawManager(uint256 amount) external onlyOwner{
        _token.transfer(msg.sender, amount);
    }
    
    
    /* ----- FUNZIONI PUBBLICHE DI LETTURA ----- */
    /* funzione pubblica di richiesta balance comprensiva di rewards (calcolate) di un indirizzo */
    function totalAmountUser(address owner) external view returns(uint256)
    {
        //require(_userLastUpdate[owner] != 0, "Address not present");
        if(_userLastUpdate[owner] == 0) return 0;
        
        uint256 ratio = TokenStakingLib.ratioX1000000(_totalStackedAmount, _usersAmount[owner]);
        uint256 rewards = TokenStakingLib.calcUserRewards(_userLastUpdate[owner], _startRewards, _stopRewards, _totalRewardAmount, ratio);
        return _usersAmount[owner].add(rewards);
    }
    /* funzione che restituisce il totale dei token in staking di un utente */
    function totalAmountStackedUser(address owner) external view returns(uint256)
    {
        //require(_userStakedAmount[owner] != 0, "Address not present");
        
        return _userStakedAmount[owner];
    }
    function totalStackedAmount() public view returns(uint256){
        return _totalStackedAmount;
    }
    function periodFinish()external view returns(uint256){
        return _stopRewards;
    }
    
    /* ----- MODIFIERS ----- */
    /* funzione pubblica di update reward nel balance utente */
    modifier updateRewards(address owner)
    {
        if(_userLastUpdate[owner] != 0)
        {
            uint256 time = block.timestamp;
            if(time > _stopRewards) time = _stopRewards;
            uint256 ratio = TokenStakingLib.ratioX1000000(_totalStackedAmount, _usersAmount[owner]);
            uint256 rewards = TokenStakingLib.calcUserRewards(_userLastUpdate[owner], _startRewards, _stopRewards, _totalRewardAmount, ratio);
            
            _usersAmount[owner] += rewards;
            _userStakedAmount[owner] += rewards;
            _userLastUpdate[owner] = time;
            _totalStackedAmount += rewards;
            
            emit UpdateRewards(owner, rewards, time);
        }
        _;
    }
    
    modifier onlyOwner(){
        require(msg.sender == manager, "user not manager");
        _;
    }
}



library TokenStakingLib {
    using SafeMath for uint256;
    
    function ratioX1000000(uint256 _totalStackedAmount, uint256 _userAmount) internal pure returns(uint256){
        return _userAmount.mul(1000000).div(_totalStackedAmount);
    }
    
    function calcUserRewards(uint256 _lastUserTimeStamp, uint256 _startRewards, uint256 _stopRewards, uint256 _totalRewardAmount, uint256  _ratioX1000000) internal view returns(uint256) {
        require(_startRewards > 0, "liquidity is not started");
        
        // periodoTotale = _stopRewards - _startRewards
        // valoreDiOgniSecondo = _totalRewardAmount / periodoTotale * 1000000
        // valoreRewardCalcolato = valoreDiOgniSecondo x (now - _lastUserTimeStamp) / 1000000 x ratioX1000000 / 1000000
        uint256 _now = block.timestamp;
        if(_now > _stopRewards) _now = _stopRewards;
        uint256 pT = _stopRewards.sub(_startRewards);
        uint256 vOS = _totalRewardAmount.mul(1000000).div(pT);
        uint256 vRewCalc = vOS.mul(_now.sub(_lastUserTimeStamp)).mul(_ratioX1000000).div(1000000000000);
        return vRewCalc;
    }
    
}