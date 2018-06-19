// Project: AleHub
// v1, 2018-05-24
// This code is the property of CryptoB2B.io
// Copying in whole or in part is prohibited.
// Authors: Ivan Fedorov and Dmitry Borodin
// Do you want the same TokenSale platform? www.cryptob2b.io

// *.sol in 1 file - https://cryptob2b.io/solidity/alehub/

pragma solidity ^0.4.21;

contract IFinancialStrategy{

    enum State { Active, Refunding, Closed }
    State public state = State.Active;

    event Deposited(address indexed beneficiary, uint256 weiAmount);
    event Receive(address indexed beneficiary, uint256 weiAmount);
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    event Started();
    event Closed();
    event RefundsEnabled();
    function freeCash() view public returns(uint256);
    function deposit(address _beneficiary) external payable;
    function refund(address _investor) external;
    function setup(uint8 _state, bytes32[] _params) external;
    function getBeneficiaryCash() external;
    function getPartnerCash(uint8 _user, address _msgsender) external;
}

contract IRightAndRoles {
    address[][] public wallets;
    mapping(address => uint16) public roles;

    event WalletChanged(address indexed newWallet, address indexed oldWallet, uint8 indexed role);
    event CloneChanged(address indexed wallet, uint8 indexed role, bool indexed mod);

    function changeWallet(address _wallet, uint8 _role) external;
    function setManagerPowerful(bool _mode) external;
    function onlyRoles(address _sender, uint16 _roleMask) view external returns(bool);
}

contract GuidedByRoles {
    IRightAndRoles public rightAndRoles;
    function GuidedByRoles(IRightAndRoles _rightAndRoles) public {
        rightAndRoles = _rightAndRoles;
    }
}

contract FinancialStrategy is IFinancialStrategy, GuidedByRoles{
    using SafeMath for uint256;

    uint8 public step;

    mapping (uint8 => mapping (address => uint256)) public deposited;

                             // Partner 0   Partner 1    Partner 2
    uint256[0] public percent;
    uint256[0] public cap; // QUINTILLIONS
    uint256[0] public debt;
    uint256[0] public total;                                 // QUINTILLIONS
    uint256[0] public took;
    uint256[0] public ready;

    address[0] public wallets;

    uint256 public benTook=0;
    uint256 public benReady=0;
    uint256 public newCash=0;
    uint256 public cashHistory=0;

    address public benWallet=0;

    modifier canGetCash(){
        require(state == State.Closed);
        _;
    }

    function FinancialStrategy(IRightAndRoles _rightAndRoles) GuidedByRoles(_rightAndRoles) public {
        emit Started();
    }

    function balance() external view returns(uint256){
        return address(this).balance;
    }

    
    function deposit(address _investor) external payable {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        require(state == State.Active);
        deposited[step][_investor] = deposited[step][_investor].add(msg.value);
        newCash = newCash.add(msg.value);
        cashHistory += msg.value;
        emit Deposited(_investor,msg.value);
    }


    // 0 - destruct
    // 1 - close
    // 2 - restart
    // 3 - refund
    // 4 - calc
    // 5 - update Exchange                                                                      
    function setup(uint8 _state, bytes32[] _params) external {
        require(rightAndRoles.onlyRoles(msg.sender,1));

        if (_state == 0)  {
            require(_params.length == 1);
            // call from Crowdsale.distructVault(true) for exit
            // arg1 - nothing
            // arg2 - nothing
            selfdestruct(address(_params[0]));

        }
        else if (_state == 1 ) {
            require(_params.length == 0);
            // Call from Crowdsale.finalization()
            //   [1] - successfull round (goalReach)
            //   [3] - failed round (not enough money)
            // arg1 = weiTotalRaised();
            // arg2 = nothing;
        
            require(state == State.Active);
            //internalCalc(_arg1);
            state = State.Closed;
            emit Closed();
        
        }
        else if (_state == 2) {
            require(_params.length == 0);
            // Call from Crowdsale.initialization()
            // arg1 = weiTotalRaised();
            // arg2 = nothing;
            require(state == State.Closed);
            require(address(this).balance == 0);
            state = State.Active;
            step++;
            emit Started();
        
        }
        else if (_state == 3 ) {
            require(_params.length == 0);
            require(state == State.Active);
            state = State.Refunding;
            emit RefundsEnabled();
        }
        else if (_state == 4) {
            require(_params.length == 2);
            //onlyPartnersOrAdmin(address(_params[1]));
            internalCalc(uint256(_params[0]));
        }
        else if (_state == 5) {
            // arg1 = old ETH/USD (exchange)
            // arg2 = new ETH/USD (_ETHUSD)
            require(_params.length == 2);
            for (uint8 user=0; user<cap.length; user++) cap[user]=cap[user].mul(uint256(_params[0])).div(uint256(_params[1]));
        }

    }

    function freeCash() view public returns(uint256){
        return newCash+benReady;
    }

    function internalCalc(uint256 _allValue) internal {

        uint256 free=newCash+benReady;
        uint256 common=0;
        uint256 prcSum=0;
        uint256 plan=0;
        uint8[] memory indexes = new uint8[](percent.length);
        uint8 count = 0;

        if (free==0) return;

        uint8 i;

        for (i =0; i <percent.length; i++) {
            plan=_allValue*percent[i]/100;

            if(cap[i] != 0 && plan > cap[i]) plan = cap[i];

            if (total[i] >= plan) {
                debt[i]=0;
                continue;
            }

            plan -= total[i];
            debt[i] = plan;
            common += plan;
            indexes[count++] = i;
            prcSum += percent[i];
        }
        if(common > free){
            benReady = 0;
            uint8 j = 0;
            while (j < count){
                i = indexes[j++];
                plan = free*percent[i]/prcSum;
                if(plan + total[i] <= cap[i] || cap[i] ==0){
                    debt[i] = plan;
                    continue;
                }
                debt[i] = cap[i] - total[i]; //&#39;total&#39; is always less than &#39;cap&#39;
                free -= debt[i];
                prcSum -= percent[i];
                indexes[j-1] = indexes[--count];
                j = 0;
            }
        }
        common = 0;
        for(i = 0; i < debt.length; i++){
            total[i] += debt[i];
            ready[i] += debt[i];
            common += ready[i];
        }
        benReady = address(this).balance - common;
        newCash = 0;
    }

    function refund(address _investor) external {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[step][_investor];
        require(depositedValue > 0);
        deposited[step][_investor] = 0;
        _investor.transfer(depositedValue);
        emit Refunded(_investor, depositedValue);
    }

    // Call from Crowdsale:
    function getBeneficiaryCash() external canGetCash {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        address _beneficiary = rightAndRoles.wallets(2,0);
        uint256 move=benReady;
        benWallet=_beneficiary;
        if (move == 0) return;

        emit Receive(_beneficiary, move);
        benReady = 0;
        benTook += move;
        
        _beneficiary.transfer(move);
    
    }


    // Call from Crowdsale:
    function getPartnerCash(uint8 _user, address _msgsender) external canGetCash {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        require(_user<wallets.length);

        onlyPartnersOrAdmin(_msgsender);

        uint256 move=ready[_user];
        if (move==0) return;

        emit Receive(wallets[_user], move);
        ready[_user]=0;
        took[_user]+=move;

        wallets[_user].transfer(move);
    
    }

    function onlyPartnersOrAdmin(address _sender) internal view {
        if (!rightAndRoles.onlyRoles(_sender,65535)) {
            for (uint8 i=0; i<wallets.length; i++) {
                if (wallets[i]==_sender) break;
            }
            if (i>=wallets.length) {
                revert();
            }
        }
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function minus(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b>=a) return 0;
        return a - b;
    }
}