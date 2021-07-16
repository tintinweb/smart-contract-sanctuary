//SourceUnit: TPT.sol

pragma solidity ^0.5.10;

interface ITRC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TPT is ITRC20 {

    string public constant name = "TronPredict Token";
    string public constant symbol = "TPT";
    uint8 public constant decimals = 6;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Burn(address indexed from, uint256 tokens);
    event Mine(address indexed miner, uint256 tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 totSupply;
    uint256 mined;

    address creator;
    address tronpredict;
    address governance;
    address dex;

    using SafeMath for uint256;

    constructor(uint256 _supply) public {
        creator = msg.sender;
        totSupply = _supply * 10 ** uint256(decimals);
        mined = 0 * 10 ** uint256(decimals);
    }

    function totalSupply() public view returns (uint256) {
        return totSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        
        return true;
    }
    
    function burn(uint256 numTokens) public returns (bool) {
        require(balances[msg.sender] >= numTokens);
        
        balances[msg.sender] -= numTokens;
        totSupply -= numTokens;
        mined -= numTokens;
        
        emit Burn(msg.sender, numTokens);
        
        return true;
    }

    function burnFrom(address owner, uint256 numTokens) public returns (bool) {
        require(balances[owner] >= numTokens);
        require(numTokens <= allowed[owner][msg.sender]);
        
        balances[owner] -= numTokens;
        allowed[owner][msg.sender] -= numTokens;
        totSupply -= numTokens;
        mined -= numTokens;
        
        emit Burn(owner, numTokens);
        
        return true;
    }
    
    function setTronPredict(address _tronpredict) public returns (bool) {
        require(msg.sender == creator, "Only the creator can set");
        
        tronpredict = _tronpredict;

        return true;
    }
    
    function setTPTGov(address _tptgov) public returns (bool) {
        require(msg.sender == creator, "Only the creator can set");
        
        governance = _tptgov;

        return true;
    }
    
    function setDEX(address _dex) public returns (bool) {
        require(msg.sender == creator, "Only the creator can set");
        
        dex = _dex;

        return true;
    }
    
    function preMine(address miner, address affiliate, uint256 amount) public returns (uint256) {
        require(msg.sender == tronpredict, "Can only be mined via TronPredict");
        
        uint256 rtn;
        
        if(amount >= 50) {
            uint256 uTokens = amount / 5;
            balances[miner] += uTokens;
            mined += uTokens;
            
            uint256 aTokens = uTokens / 2;
            balances[affiliate] += aTokens;
            mined += aTokens;
            
            uint256 gTokens = (uTokens * 96) / 100;
            balances[governance] += gTokens;
            mined += gTokens;
            
            uint256 mTokens = uTokens + aTokens + gTokens;
            
            emit Mine(miner, mTokens);
            
            rtn = mTokens;
        } else {
            rtn = 0;
        }

        return rtn;
    }
    
    function mine(address miner, address affiliate, uint256 amount, uint256 divisible) public returns (uint256) {
        require(msg.sender == tronpredict, "Can only be mined via TronPredict");

        uint256 rtn;
        
        if(mined < totSupply) {
            uint256 uTokens = amount / divisible;
            balances[miner] += uTokens;
            mined += uTokens;
            
            uint256 aTokens = uTokens / 2;
            balances[affiliate] += aTokens;
            mined += aTokens;
            
            uint256 gTokens = (uTokens * 96) / 100;
            balances[governance] += gTokens;
            mined += gTokens;
            
            uint256 mTokens = uTokens + aTokens + gTokens;
            
            emit Mine(miner, mTokens);
            
            rtn = mTokens;
        } else {
            rtn = 0;
        }
        
        return rtn;
    }
    
    function dexmine(address miner, uint256 numTokens) public returns (bool) {
        require(msg.sender == dex, "Can only be mined by Approved DEX");
        require(mined < totSupply);

        balances[miner] += numTokens;
        mined += numTokens;
        
        emit Mine(miner, numTokens);
        
        return true;
    }
    
    function totalMined() public view returns (uint256) {
        return mined;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}


//SourceUnit: TRONPREDICTV3.sol

pragma solidity ^0.5.9;

import './TPT.sol';

contract TRONPREDICTV3 {
    
    address creator;
    address payable governance;
    address tronpredicttoken;
    
    uint governancebalance = 0;
    uint preminestamp;
    uint divisible;

    constructor(address payable _governance, uint _initialdivisible) public {
        creator = msg.sender;
        governance = _governance;
        divisible = _initialdivisible;
    }
    
    struct predictionasset {
        string coin;
        string date;
        uint cycle;
        uint openprice;
        uint closeprice;
        uint pricehigh;
        uint pricelow;
        bool isclosed;
        uint totstake;
        uint totpreds;
        uint totmined;
    }
    
    mapping(uint => predictionasset) predictionassets;
    
    struct predcount {
        uint count;
    }
    
    mapping(uint => predcount) predcounts;
    
    struct predictor {
        address user;
        address payable affiliate;
        uint asset;
        uint predid;
        uint stake;
        uint reward;
        uint stamp;
        bool iscorrect;
        bool rewardpaid;
    }
    
    mapping(uint => predictor) predictors;
    
    struct prediction {
        uint totpreds;
        uint totstake;
        uint rewardperc;
        bool iscorrect;
    }
    
    mapping(uint => prediction) predictions;
    
    struct affiliate {
        uint totbalance;
    }
    
    mapping(address => affiliate) affiliates;
    
    struct usertransaction {
        uint[] transactions;
    }
    
    mapping(address => usertransaction) usertransactions;
    
    struct affiliatetransaction {
        uint[] transactions;
    }
    
    mapping(address => affiliatetransaction) affiliatetransactions;
    
    struct predictiontransaction {
        uint[] transactions;
    }
    
    mapping(uint => predictiontransaction) predictiontransactions;
    
    struct assetreward {
        uint tot;
        uint totpredictors;
        uint totallocated;
        uint totpaid;
    }
    
    mapping(uint => assetreward) assetrewards;
    
    // set token contract address
    function settokenaddress(address tpt) external {
        if(msg.sender == creator) {
            tronpredicttoken = tpt;
        }
    }
    
    // set pre-mine end date
    function setpreminestamp(uint stamp) external {
        if(msg.sender == creator) {
            preminestamp = stamp;
        }
    }
    
    // add new prediction asset
    function addpredictionasset(
        uint _asset,
        string calldata _coin,
        string calldata _date,
        uint _cycle,
        uint _openprice,
        uint _pricehigh,
        uint _pricelow,
        uint _predcount
    ) external {
        if(msg.sender == creator) {
            predictionassets[_asset] = predictionasset(_coin,_date,_cycle,_openprice,0,_pricehigh,_pricelow,false,0,0,0);
            predcounts[_asset] = predcount(_predcount);
            assetrewards[_asset] = assetreward(0,0,0,0);
        }
    }
    
    // set daily divisible
    function setdivisible() external {
        if(msg.sender == creator) {
            if(now > preminestamp) {
                divisible += 50;
            }
        }
    }
    
    // close prediction asset
    function closepredictionasset(
        uint _asset
    ) external {
        if(msg.sender == creator) {
            predictionassets[_asset].isclosed = true;
        }
    }
    
    // set prediction asset's closeprice
    function setpredictionassetcloseprice(
        uint _asset,
        uint _closeprice
    ) external {
        if(msg.sender == creator) {
            predictionassets[_asset].closeprice = _closeprice;
            
            uint _predra = (_asset * 10) + 1;
            uint _predrb = (_asset * 10) + 2;
            uint _predfb = (_asset * 10) + 3;
            
            uint _predcorrect;
            
            uint ph = predictionassets[_asset].pricehigh;
            uint pl = predictionassets[_asset].pricelow;
            
            if(_closeprice > ph) {
                // RA prediction correct
                _predcorrect = _predra;
            } else if(_closeprice < pl) {
                // FB prediction correct 
                _predcorrect = _predfb;
            } else {
                // RB prediction correct 
                _predcorrect = _predrb;
            }
            
            predictions[_predcorrect].iscorrect = true;
        }
    }
    
    // set prediction asset's reward
    uint _userrewardperc = 0;
    uint _devrewardperc = 0;
    uint _benrewardperc = 0;
                
    function setpredictionassetreward(
        uint _asset
    ) external {
        if(msg.sender == creator) {
            if(predictionassets[_asset].totpreds > 0) {
                uint _predra = (_asset * 10) + 1;
                uint _predrb = (_asset * 10) + 2;
                uint _predfb = (_asset * 10) + 3;
                
                uint _predcorrect;
                uint _totloss;
                uint _totwin;
                uint rwrd;
                
                if(predictions[_predra].iscorrect == true) {
                    _predcorrect = _predra;
                    
                    _totwin = predictions[_predra].totstake;
                    _totloss = predictions[_predrb].totstake + predictions[_predfb].totstake;
                } else if(predictions[_predrb].iscorrect == true) {
                    _predcorrect = _predrb;
                    
                    _totwin = predictions[_predrb].totstake;
                    _totloss = predictions[_predra].totstake + predictions[_predfb].totstake;
                } else if(predictions[_predfb].iscorrect == true) {
                    _predcorrect = _predfb;
                    
                    _totwin = predictions[_predfb].totstake;
                    _totloss = predictions[_predra].totstake + predictions[_predrb].totstake;
                }
                
                _userrewardperc = (_totloss * 90) / _totwin;
                _devrewardperc = (_totloss * 6) / _totwin;
                _benrewardperc = (_totloss * 4) / _totwin;
                
                if(_userrewardperc < 1) {
                    _userrewardperc = (_totloss * 100) / _totwin;
                    _devrewardperc = 0;
                    _benrewardperc = 0;
                }
                
                predictions[_predcorrect].rewardperc = _userrewardperc;
                
                assetrewards[_asset].tot = _totloss;
                assetrewards[_asset].totpredictors = (predictions[_predcorrect].totstake * _userrewardperc) / 100;
                
                uint len = predictiontransactions[_predcorrect].transactions.length;
    
                for(uint i = 0; i < len; i++) {
                    uint predtx = predictiontransactions[_predcorrect].transactions[i];
                    
                    if(predictors[predtx].predid == _predcorrect) {
                        rwrd = (predictors[predtx].stake * _userrewardperc) / 100;
                        predictors[predtx].reward = rwrd;
                        predictors[predtx].iscorrect = true;
                        
                        assetrewards[_asset].totallocated = assetrewards[_asset].totallocated + rwrd;
                        
                        rwrd = (predictors[predtx].stake * _devrewardperc) / 100;
                        affiliates[predictors[predtx].affiliate].totbalance = affiliates[predictors[predtx].affiliate].totbalance + rwrd;
                        
                        rwrd = (predictors[predtx].stake * _benrewardperc) / 100;
                        governancebalance = governancebalance + rwrd;
                    }
                }
            }
            
            _userrewardperc = 0;
            _devrewardperc = 0;
            _benrewardperc = 0;
        }
    }
    
    // make prediction
    event makeuserpredictionevent(
        uint indexed _stamp,
        address indexed _user,
        address indexed _affiliate,
        uint _predtx,
        uint _asset,
        uint _pred,
        uint _value
    );
    
    function makeuserprediction(
        uint _asset,
        uint _pred,
        address payable _affiliate
    ) external payable {
        require(msg.value > 0, "Stake cannot be 0 TRX.");
        require(predictionassets[_asset].isclosed == false, "Predictions closed. Please wait for next prediction cycle.");
        
        uint userpredcount = predcounts[_asset].count;
        predcounts[_asset].count++;
        
        predictors[userpredcount] = predictor(msg.sender,_affiliate,_asset,_pred,msg.value,0,now,false,false);
        usertransactions[msg.sender].transactions.push(userpredcount);
        affiliatetransactions[_affiliate].transactions.push(userpredcount);

        if(predictors[userpredcount].user == msg.sender && predictors[userpredcount].predid == _pred && predictors[userpredcount].stake == msg.value) {
            predictiontransactions[_pred].transactions.push(userpredcount);
            
            predictions[_pred].totpreds = predictions[_pred].totpreds + 1;
            predictions[_pred].totstake = predictions[_pred].totstake + msg.value;
            
            predictionassets[_asset].totpreds = predictionassets[_asset].totpreds + 1;
            predictionassets[_asset].totstake = predictionassets[_asset].totstake + msg.value;
            
            emit makeuserpredictionevent(now,msg.sender,_affiliate,userpredcount,_asset,_pred,msg.value);
            
            TPT tpt = TPT(tronpredicttoken);
            uint256 mined;
            
            if(now <= preminestamp) {
                mined = tpt.preMine(msg.sender, _affiliate, msg.value);
            } else {
                mined = tpt.mine(msg.sender, _affiliate, msg.value, divisible);
            }
            
            predictionassets[_asset].totmined = predictionassets[_asset].totmined + mined;
            
        } else {
            revert("Transaction failed");
        }
    }
    
    // withdraw user reward
    event withdrawuserrewardevent(
        uint indexed _stamp,
        address indexed _user,
        uint _asset,
        uint _predtx,
        uint _value
    );
    
    function withdrawuserreward(
        uint _asset,
        uint _predtx
    ) external {
        address usr = predictors[_predtx].user;
        uint stk = predictors[_predtx].stake;
        uint rwrd = predictors[_predtx].reward;
        bool iscrct = predictors[_predtx].iscorrect;
        bool rwrdpd = predictors[_predtx].rewardpaid;
        
        if(msg.sender == usr && iscrct == true && rwrdpd == false) {
            uint payamount = stk + rwrd;
            
            bool success = msg.sender.send(payamount);
            
            if(success == true) {
                predictors[_predtx].rewardpaid = true;
                assetrewards[_asset].totpaid = assetrewards[_asset].totpaid + rwrd;
                
                emit withdrawuserrewardevent(now,msg.sender,_asset,_predtx,payamount);
            }
        }
    }
    
    // withdraw affiliate reward
    event withdrawaffiliaterewardevent(
        uint indexed _stamp,
        address indexed _affiliate,
        uint _value
    );
    
    function withdrawaffiliatereward() external {
        uint payamount = affiliates[msg.sender].totbalance;
        
        bool success = msg.sender.send(payamount);
            
        if(success == true) {
            affiliates[msg.sender].totbalance = 0;
            
            emit withdrawaffiliaterewardevent(now,msg.sender,payamount);
        }
    }
    
    // withdraw governance reward
    event withdrawgovernancerewardevent(
        uint indexed _stamp,
        uint _value
    );
    
    function withdrawgovernancereward() external {
        if(msg.sender == creator) {
            bool success = governance.send(governancebalance);
            
            if(success == true) {
                emit withdrawgovernancerewardevent(now,governancebalance);
                
                governancebalance = 0;
            }
        }
    }
    
    // get prediction asset
    function getpredictionasset(uint _asset) external view returns(
        string memory a,
        string memory b,
        uint c,
        uint d,
        uint e,
        uint f,
        uint g,
        bool h,
        uint i,
        uint j,
        uint k
    ) {
        a = predictionassets[_asset].coin;
        b = predictionassets[_asset].date; 
        c = predictionassets[_asset].cycle;
        d = predictionassets[_asset].openprice;
        e = predictionassets[_asset].closeprice;
        f = predictionassets[_asset].pricehigh;
        g = predictionassets[_asset].pricelow;
        h = predictionassets[_asset].isclosed;
        i = predictionassets[_asset].totstake;
        j = predictionassets[_asset].totpreds;
        k = predictionassets[_asset].totmined;
    }
    
    // get predictions statistics
    // rise above
    function getrapredictionsstats(uint _asset) external view returns(
        uint raa,
        uint rab,
        bool rac,
        uint rad
    ) {
        uint _predra = (_asset * 10) + 1;
        
        // rise statistics
        raa = predictions[_predra].totpreds;
        rab = predictions[_predra].totstake;
        rac = predictions[_predra].iscorrect;
        rad = predictions[_predra].rewardperc;
    }
    // range between
    function getrbpredictionsstats(uint _asset) external view returns(
        uint rba,
        uint rbb,
        bool rbc,
        uint rbd
    ) {
        uint _predrb = (_asset * 10) + 2;
        
        // range between statistics
        rba = predictions[_predrb].totpreds;
        rbb = predictions[_predrb].totstake;
        rbc = predictions[_predrb].iscorrect;
        rbd = predictions[_predrb].rewardperc;
    }
    // fall below
    function getfbpredictionsstats(uint _asset) external view returns(
        uint fba,
        uint fbb,
        bool fbc,
        uint fbd
    ) {
        uint _predfb = (_asset * 10) + 3;
        
        // fall statistics
        fba = predictions[_predfb].totpreds;
        fbb = predictions[_predfb].totstake;
        fbc = predictions[_predfb].iscorrect;
        fbd = predictions[_predfb].rewardperc;
    }
    
    // get asset rewards
    function getassetrewards(uint _asset) external view returns(
        uint a,
        uint b,
        uint c,
        uint d
    ) {
        a = assetrewards[_asset].tot;
        b = assetrewards[_asset].totpredictors;
        c = assetrewards[_asset].totallocated;
        d = assetrewards[_asset].totpaid;
    }
    
    // get number of user transactions
    function getnumusertransactions() external view returns(uint) {
        return usertransactions[msg.sender].transactions.length;
    }
    
    // get number of affiliate transactions
    function getnumaffiliatetransactions() external view returns(uint) {
        return affiliatetransactions[msg.sender].transactions.length;
    }
    
    // get list user transaction
    function getlistusertransaction(uint _ind) external view returns(
        bool isusertx,
        uint predtx,
        uint a,
        uint b,
        uint c,
        uint d,
        bool e
    ) {
        predtx = usertransactions[msg.sender].transactions[_ind];
        address user = predictors[predtx].user;
        
        if(msg.sender == user) {
            isusertx = true;
            a = predictors[predtx].asset;
            b = predictors[predtx].predid;
            c = predictors[predtx].stake;
            d = predictors[predtx].stamp;
            e = predictors[predtx].iscorrect;
        } else {
            isusertx = false;
            predtx = 0;
            a = 0;
            b = 0;
            c = 0;
            d = 0;
            e = false;
        }
    }
    
    // get list affiliate transaction
    function getlistaffiliatetransaction(uint _ind) external view returns(
        bool isaffiliatetx,
        uint predtx,
        uint a,
        uint b,
        uint c,
        uint d,
        bool e
    ) {
        predtx = affiliatetransactions[msg.sender].transactions[_ind];
        address affl = predictors[predtx].affiliate;
        
        if(msg.sender == affl) {
            isaffiliatetx = true;
            a = predictors[predtx].asset;
            b = predictors[predtx].predid;
            c = predictors[predtx].stake;
            d = predictors[predtx].stamp;
            e = predictors[predtx].iscorrect;
        } else {
            isaffiliatetx = false;
            predtx = 0;
            a = 0;
            b = 0;
            c = 0;
            d = 0;
            e = false;
        }
    }
    
    // get user transaction
    function getusertransaction(uint _predtx) external view returns(
        bool isusertx,
        uint a,
        uint b,
        uint c,
        uint d,
        uint e,
        bool f,
        bool g
    ) {
        address user = predictors[_predtx].user;
        
        if(msg.sender == user) {
            isusertx = true;
            a = predictors[_predtx].asset;
            b = predictors[_predtx].predid;
            c = predictors[_predtx].stake;
            d = predictors[_predtx].reward;
            e = predictors[_predtx].stamp;
            f = predictors[_predtx].iscorrect;
            g = predictors[_predtx].rewardpaid;
        } else {
            isusertx = false;
            a = 0;
            b = 0;
            c = 0;
            d = 0;
            e = 0;
            f = false;
            g = false;
        }
    }
    
    // get contract balance
    function getcontractbalance() external view returns(uint) {
        uint bal = 0;
        
        if(msg.sender == creator) {
            bal = address(this).balance;
        }
        
        return bal;
    }
    
    // get governance balance
    function getgovernancebalance() external view returns(uint) {
        uint bal = 0;
        
        if(msg.sender == creator) {
            bal = governancebalance;
        }
        
        return bal;
    }
    
    // get affiliate balance
    function getaffiliatebalance() external view returns(uint) {
        return affiliates[msg.sender].totbalance;
    }
    
    // get mining divisible
    function getpreminestamp() external view returns(uint) {
        return preminestamp;
    }
    
    // get mining divisible
    function getminingdivisible() external view returns(uint) {
        return divisible;
    }
    
}