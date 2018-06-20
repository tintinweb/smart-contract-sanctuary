pragma solidity ^0.4.18;

    contract Owned {

        modifier onlyOwner { require(msg.sender == owner); _; }

        address public owner;

        function Owned() public { owner = msg.sender;}

        function changeOwner(address _newOwner) public onlyOwner {
            owner = _newOwner;
        }
    }

    contract TokenController {

        function onTransfer(address _from, address _to, uint _amount) public returns(bool);

        function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
    }

    contract ApproveAndCallFallBack {
        function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
    }

    contract KayoToken is Owned {

        string public name;                
        uint8 public decimals;             
        string public symbol;              

        struct  Checkpoint {

            uint128 fromBlock;

            uint128 value;
        }

        KayoToken public parentToken;

        uint public parentSnapShotBlock;

        uint public creationBlock;

        mapping (address => Checkpoint[]) balances;

        uint public preSaleTokenBalances;

        mapping (address => mapping (address => uint256)) allowed;

        Checkpoint[] totalSupplyHistory;

        bool public tradeEnabled;
        
        bool public IsPreSaleEnabled = false;

        bool public IsSaleEnabled = false;

        bool public IsAirDropEnabled = false;
        
        address public owner;

        address public airDropManager;
        
        uint public allowedAirDropTokens;

        mapping (address => bool) public frozenAccount;
        event FrozenFunds(address target, bool frozen);
        
        function KayoToken(
            address _tokenFactory,
            address _parentToken,
            uint _parentSnapShotBlock,
            string _tokenName,
            uint8 _decimalUnits,
            string _tokenSymbol,
            bool _tradeEnabled
        ) public {
            owner = _tokenFactory;
            name = _tokenName;                                 
            decimals = _decimalUnits;                          
            symbol = _tokenSymbol;                             
            parentToken = KayoToken(_parentToken);
            parentSnapShotBlock = _parentSnapShotBlock;
            tradeEnabled = _tradeEnabled;
            creationBlock = block.number;
        }

        function IsAirdrop() public view returns (bool result){
            if(msg.sender == airDropManager)
                return true;
            else
                return false;
        }

        function IsReleaseToken() public view returns(bool result){
            if ((IsSaleEnabled == true || IsPreSaleEnabled == true) && msg.sender == owner)
                return true;
            else
                return false;
        }


        function transfer(address _to, uint256 _amount) public returns (bool success) {
            require(tradeEnabled);
            transferFrom(msg.sender, _to, _amount);
            return true;
        }

        function freezeAccount(address target, bool freeze) onlyOwner public{
            frozenAccount[target] = freeze;
            FrozenFunds(target, freeze);
        }

        function setPreSale (bool _value) onlyOwner public {
            IsPreSaleEnabled = _value;
        }

        function setSale (bool _value) onlyOwner public {
            IsSaleEnabled = _value;
        }

        function setAirDrop (bool _value) onlyOwner public {
            IsAirDropEnabled = _value;
        }

        function setAirDropManager (address _address) onlyOwner public{
            airDropManager = _address;
        }

        function setairDropManagerLimit(uint _amount) onlyOwner public returns (bool success){
            allowedAirDropTokens = _amount;
            approve(airDropManager, _amount);
            return true;
        }

        function airDrop(address _to, uint256 _amount) public returns (bool success){
            
            require(IsAirDropEnabled);
            require((_to != 0) && (_to != address(this)));

            transferFrom(owner, _to, _amount);
            return true;
        }

        function invest(address _to, uint256 _amount) public returns (bool success) {
            
            require((_to != 0) && (_to != address(this)));

            if(IsPreSaleEnabled){
                require(preSaleTokenBalances >= _amount);
                preSaleTokenBalances = preSaleTokenBalances - _amount;
            }
            else if(!IsSaleEnabled){
                revert();
            }
            
            transferFrom(msg.sender, _to, _amount);
            return true;
        }

        function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {

            if(IsReleaseToken() || IsAirdrop() || tradeEnabled == true){
                if (_amount == 0) {
                    Transfer(_from, _to, _amount);
                    return;
                }

                if (msg.sender != owner) {
                    require(allowed[_from][msg.sender] >= _amount);
                    allowed[_from][msg.sender] -= _amount;
                }

                var previousBalanceFrom = balanceOfAt(_from, block.number);
                var previousBalanceTo = balanceOfAt(_to, block.number);

                require(previousBalanceFrom >= _amount);
                require(previousBalanceTo + _amount >= previousBalanceTo);

                updateValueAtNow(balances[msg.sender], previousBalanceFrom - _amount);
                updateValueAtNow(balances[_to], previousBalanceTo + _amount);

                Transfer(_from, _to, _amount);

                return true;
            }
            else
                revert();
        }

        function balanceOf(address _owner) public constant returns (uint256 tokenBalance) {
            return balanceOfAt(_owner, block.number);
        }

        function approve(address _spender, uint256 _amount) public returns (bool success) {

            require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

            if (isValidAddress(owner)) {
                require(TokenController(owner).onApprove(msg.sender, _spender, _amount));
            }

            allowed[msg.sender][_spender] = _amount;
            Approval(msg.sender, _spender, _amount);
            return true;
        }

        function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
            return allowed[_owner][_spender];
        }

        function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool success) {

            require(approve(_spender, _amount));
            ApproveAndCallFallBack(_spender).receiveApproval(msg.sender,_amount,this,_extraData);
            return true;
        }

        function totalSupply() public constant returns (uint) {
            return totalSupplyAt(block.number);
        }

        function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint) {

            if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
                if (address(parentToken) != 0) {
                    return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
                } else {
                    return 0;
                }

            } else {
                return getValueAt(balances[_owner], _blockNumber);
            }
        }

        function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

            if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
                if (address(parentToken) != 0) {
                    return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
                } else {
                    return 0;
                }

            } else {
                return getValueAt(totalSupplyHistory, _blockNumber);
            }
        }

        function generateTokens(address _owner, uint _amount) public onlyOwner returns (bool) {
            uint curTotalSupply = totalSupply();
            require(curTotalSupply + _amount >= curTotalSupply);
            uint previousBalanceTo = balanceOf(_owner);
            require(previousBalanceTo + _amount >= previousBalanceTo);

            updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
            updateValueAtNow(balances[_owner], previousBalanceTo + _amount);

            uint256 _bal = _amount * 30;
            preSaleTokenBalances = preSaleTokenBalances + _bal / 100;
            Transfer(0, _owner, _amount);
            return true;
        }

        function destroyTokens(address _address, uint _amount) onlyOwner public returns (bool) {
            uint curTotalSupply = totalSupply();
            require(curTotalSupply >= _amount);
            uint previousBalanceFrom = balanceOf(_address);
            require(previousBalanceFrom >= _amount);
            updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
            updateValueAtNow(balances[_address], previousBalanceFrom - _amount);
            Transfer(_address, owner, _amount);
            return true;
        }
        
        function destroyAllTokens() onlyOwner public returns (bool) {
            uint curBalance = balanceOfAt(msg.sender, block.number);
            updateValueAtNow(totalSupplyHistory, 0);
            updateValueAtNow(balances[msg.sender], 0);
            preSaleTokenBalances = 0;
            Transfer(msg.sender, 0, curBalance);
            return true;
        }

        function enableTransfers(bool _tradeEnabled) public onlyOwner {
            tradeEnabled = _tradeEnabled;
        }

        function getValueAt(Checkpoint[] storage checkpoints, uint _block) constant internal returns (uint) {
            
            if (checkpoints.length == 0) return 0;

            if (_block >= checkpoints[checkpoints.length-1].fromBlock)
                return checkpoints[checkpoints.length-1].value;

            if (_block < checkpoints[0].fromBlock) return 0;

            uint minValue = 0;
            uint maximum = checkpoints.length-1;
            while (maximum > minValue) {
                uint midddle = (maximum + minValue + 1)/ 2;
                if (checkpoints[midddle].fromBlock<=_block) {
                    minValue = midddle;
                } else {
                    maximum = midddle-1;
                }
            }
            return checkpoints[minValue].value;
        }

        function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal  {
            if ((checkpoints.length == 0) || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
                Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
                newCheckPoint.fromBlock =  uint128(block.number);
                newCheckPoint.value = uint128(_value);
            } else {
                Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
                oldCheckPoint.value = uint128(_value);
            }
        }

        function isValidAddress(address _addr) constant internal returns(bool) {
            uint size;
            if (_addr == 0) return false;
            assembly {
                size := extcodesize(_addr)
            }
            return size > 0;
        }

        function min(uint a, uint b) pure internal returns (uint) {
            return a < b ? a : b;
        }

        event Transfer(address indexed _from, address indexed _to, uint256 _amount);
        event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

    }