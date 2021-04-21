/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
}

contract owned {
    address public owner;
    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != 0x0);
        owner = newOwner;
    }
}

contract BasicToken is owned {
    using SafeMath for uint256;

    mapping (address => uint256) internal balance_of;
    mapping (address => mapping (address => uint256)) internal allowances;

    mapping (address => bool) private address_exist;
    address[] private address_list;

    bool public transfer_close = false;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function BasicToken() public {
    }

    function balanceOf(address token_owner) public constant returns (uint balance) {
        return balance_of[token_owner];
    }

    function allowance(
        address _hoarder,
        address _spender
    ) public constant returns (uint256) {
        return allowances[_hoarder][_spender];
    }

    function superApprove(
        address _hoarder,
        address _spender,
        uint256 _value
    ) onlyOwner public returns(bool) {
        require(_hoarder != address(0));
        require(_spender != address(0));
        require(_value >= 0);
        allowances[_hoarder][_spender] = _value;
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(msg.sender != address(0));
        require(_spender != address(0));
        require(_value >= 0);
        allowances[msg.sender][_spender] = _value;
        return true;
    }

    function getAddressLength() onlyOwner public constant returns (uint) {
        return address_list.length;
    }

    function getAddressIndex(uint _address_index) onlyOwner public constant returns (address _address) {
        _address = address_list[_address_index];
    }

    function getAllAddress() onlyOwner public constant returns (address[]) {
        return address_list;
    }

    function getAddressExist(address _target) public constant returns (bool) {
        if (_target == address(0)) {
            return false;
        } else {
            return address_exist[_target];
        }
    }

    function addAddress(address _target) internal returns(bool) {
        if (_target == address(0)) {
            return false;
        } else if (address_exist[_target] == true) {
            return false;
        } else {
            address_exist[_target] = true;
            address_list[address_list.length++] = _target;
        }
    }

    function mintToken(
        address _to,
        uint256 token_amount,
        uint256 freeze_timestamp
    ) onlyOwner public returns (bool);

    function superMint(
        address _to,
        uint256 token_amount,
        uint256 freeze_timestamp) onlyOwner public returns(bool);

    function transfer(address to, uint256 value) public;
    function transferFrom(address _from, address _to, uint256 _amount) public;

    function transferOpen() onlyOwner public {
        transfer_close = false;
    }

    function transferClose() onlyOwner public {
        transfer_close = true;
    }
}

contract PreSale is owned{
    using SafeMath for uint256;

    struct Sale {
        uint sale_number;
        uint256 start_timestamp;
        uint256 end_timestamp;
        uint8 bonus_rate;
        uint256 sell_limit;
    }

    Sale[] private sale_list;
    uint256[] private sale_sold;

    function PreSale () public {

    }

    function getSaleLength() public constant returns(uint) {
        return sale_list.length;
    }

    function getSaleInfo(uint _index) public constant returns(
        uint sale_number,
        uint256 start_timestamp,
        uint256 end_timestamp,
        uint8 bonus_rate,
        uint256 sell_limit
    ) {
        sale_number = sale_list[_index].sale_number;
        start_timestamp = sale_list[_index].start_timestamp;
        end_timestamp = sale_list[_index].end_timestamp;
        bonus_rate = sale_list[_index].bonus_rate;
        sell_limit = sale_list[_index].sell_limit;
    }

    function getSaleSold(uint _index) public constant returns(uint256) {
        return sale_sold[_index];
    }


    function addBonus(
        uint256 _amount,
        uint8 _bonus
    ) internal pure returns(uint256) {
        return _amount.add((_amount.mul(_bonus)).div(100));
    }


    function newSale(
        uint256 start_timestamp,
        uint256 end_timestamp,
        uint8 bonus_rate,
        uint256 sell_token_limit
    ) onlyOwner public {
        require(start_timestamp > 0);
        require(end_timestamp > 0);
        require(sell_token_limit > 0);

        uint256 sale_number = sale_list.length;
        for (uint i=0; i < sale_list.length; i++) {
            require(sale_list[i].end_timestamp < start_timestamp);
        }

        sale_list[sale_list.length++] = Sale({
            sale_number: sale_number,
            start_timestamp: start_timestamp,
            end_timestamp: end_timestamp,
            bonus_rate: bonus_rate,
            sell_limit: sell_token_limit
        });
        sale_sold[sale_sold.length++] = 0;
    }

    function changeSaleInfo(
        uint256 _index,
        uint256 start_timestamp,
        uint256 end_timestamp,
        uint8 bonus_rate,
        uint256 sell_token_limit
    ) onlyOwner public returns(bool) {
        require(_index < sale_list.length);
        require(start_timestamp > 0);
        require(end_timestamp > 0);
        require(sell_token_limit > 0);

        sale_list[_index].start_timestamp = start_timestamp;
        sale_list[_index].end_timestamp = end_timestamp;
        sale_list[_index].bonus_rate = bonus_rate;
        sale_list[_index].sell_limit = sell_token_limit;
        return true;
    }

    function changeSaleStart(
        uint256 _index,
        uint256 start_timestamp
    ) onlyOwner public returns(bool) {
        require(_index < sale_list.length);
        require(start_timestamp > 0);
        sale_list[_index].start_timestamp = start_timestamp;
        return true;
    }

    function changeSaleEnd(
        uint256 _index,
        uint256 end_timestamp
    ) onlyOwner public returns(bool) {
        require(_index < sale_list.length);
        require(end_timestamp > 0);
        sale_list[_index].end_timestamp = end_timestamp;
        return true;
    }

    function changeSaleBonusRate(
        uint256 _index,
        uint8 bonus_rate
    ) onlyOwner public returns(bool) {
        require(_index < sale_list.length);
        sale_list[_index].bonus_rate = bonus_rate;
        return true;
    }

    function changeSaleTokenLimit(
        uint256 _index,
        uint256 sell_token_limit
    ) onlyOwner public returns(bool) {
        require(_index < sale_list.length);
        require(sell_token_limit > 0);
        sale_list[_index].sell_limit = sell_token_limit;
        return true;
    }


    function checkSaleCanSell(
        uint256 _index,
        uint256 _amount
    ) internal view returns(bool) {
        uint256 index_sold = sale_sold[_index];
        uint256 index_end_timestamp = sale_list[_index].end_timestamp;
        uint256 sell_limit = sale_list[_index].sell_limit;
        uint8 bonus_rate = sale_list[_index].bonus_rate;
        uint256 sell_limit_plus_bonus = addBonus(sell_limit, bonus_rate);

        if (now >= index_end_timestamp) {
            return false;
        } else if (index_sold.add(_amount) > sell_limit_plus_bonus) {
            return false;
        } else {
            return true;
        }
    }

    function addSaleSold(uint256 _index, uint256 amount) internal {
        require(amount > 0);
        require(_index < sale_sold.length);
        require(checkSaleCanSell(_index, amount) == true);
        sale_sold[_index] += amount;
    }

    function subSaleSold(uint256 _index, uint256 amount) internal {
        require(amount > 0);
        require(_index < sale_sold.length);
        require(sale_sold[_index].sub(amount) >= 0);
        sale_sold[_index] -= amount;
    }

    function canSaleInfo() public view returns(
        uint sale_number,
        uint256 start_timestamp,
        uint256 end_timestamp,
        uint8 bonus_rate,
        uint256 sell_limit
    ) {
        var(sale_info, isSale) = nowSaleInfo();
        require(isSale == true);
        sale_number = sale_info.sale_number;
        start_timestamp = sale_info.start_timestamp;
        end_timestamp = sale_info.end_timestamp;
        bonus_rate = sale_info.bonus_rate;
        sell_limit = sale_info.sell_limit;
    }

    function nowSaleInfo() internal view returns(Sale sale_info, bool isSale) {
        isSale = false;
        for (uint i=0; i < sale_list.length; i++) {
            uint256 end_timestamp = sale_list[i].end_timestamp;
            uint256 sell_limit = sale_list[i].sell_limit;
            uint8 bonus_rate = sale_list[i].bonus_rate;
            uint256 sell_limit_plus_bonus = addBonus(sell_limit, bonus_rate);
            uint256 temp_sold_token = sale_sold[i];
            if ((now <= end_timestamp) && (temp_sold_token < sell_limit_plus_bonus)) {
                sale_info = Sale({
                    sale_number: sale_list[i].sale_number,
                    start_timestamp: sale_list[i].start_timestamp,
                    end_timestamp: sale_list[i].end_timestamp,
                    bonus_rate: sale_list[i].bonus_rate,
                    sell_limit: sale_list[i].sell_limit
                });
                isSale = true;
                break;
            } else {
                isSale = false;
                continue;
            }
        }
    }
}

contract Vote is owned {
    event ProposalAdd(uint vote_id, address generator, string descript);
    event ProposalEnd(uint vote_id, string descript);

    struct Proposal {
        address generator;
        string descript;
        uint256 start_timestamp;
        uint256 end_timestamp;
        bool executed;
        uint256 voting_cut;
        uint256 threshold;

        uint256 voting_count;
        uint256 total_weight;
        mapping (address => uint256) voteWeightOf;
        mapping (address => bool) votedOf;
        address[] voter_address;
    }

    uint private vote_id = 0;
    Proposal[] private Proposals;

    function getProposalLength() public constant returns (uint) {
        return Proposals.length;
    }

    function getProposalIndex(uint _proposal_index) public constant returns (
        address generator,
        string descript,
        uint256 start_timestamp,
        uint256 end_timestamp,
        bool executed,
        uint256 voting_count,
        uint256 total_weight,
        uint256 voting_cut,
        uint256 threshold
    ) {
        generator = Proposals[_proposal_index].generator;
        descript = Proposals[_proposal_index].descript;
        start_timestamp = Proposals[_proposal_index].start_timestamp;
        end_timestamp = Proposals[_proposal_index].end_timestamp;
        executed = Proposals[_proposal_index].executed;
        voting_count = Proposals[_proposal_index].voting_count;
        total_weight = Proposals[_proposal_index].total_weight;
        voting_cut = Proposals[_proposal_index].voting_cut;
        threshold = Proposals[_proposal_index].threshold;
    }

    function getProposalVoterList(uint _proposal_index) public constant returns (address[]) {
        return Proposals[_proposal_index].voter_address;
    }

    function newVote(
        address who,
        string descript,
        uint256 start_timestamp,
        uint256 end_timestamp,
        uint256 voting_cut,
        uint256 threshold
    ) onlyOwner public returns (uint256) {
        if (Proposals.length >= 1) {
            require(Proposals[vote_id].end_timestamp < start_timestamp);
            require(Proposals[vote_id].executed == true);
        }

        vote_id = Proposals.length;
        Proposal storage p = Proposals[Proposals.length++];
        p.generator = who;
        p.descript = descript;
        p.start_timestamp = start_timestamp;
        p.end_timestamp = end_timestamp;
        p.executed = false;
        p.voting_cut = voting_cut;
        p.threshold = threshold;

        p.voting_count = 0;
        delete p.voter_address;
        ProposalAdd(vote_id, who, descript);
        return vote_id;
    }

    function voting(address _voter, uint256 _weight) internal returns(bool) {
        if (Proposals[vote_id].end_timestamp < now) {
            Proposals[vote_id].executed = true;
        }

        require(Proposals[vote_id].executed == false);
        require(Proposals[vote_id].end_timestamp > now);
        require(Proposals[vote_id].start_timestamp <= now);
        require(Proposals[vote_id].votedOf[_voter] == false);
        require(Proposals[vote_id].voting_cut <= _weight);

        Proposals[vote_id].votedOf[_voter] = true;
        Proposals[vote_id].voting_count += 1;
        Proposals[vote_id].voteWeightOf[_voter] = _weight;
        Proposals[vote_id].total_weight += _weight;
        Proposals[vote_id].voter_address[Proposals[vote_id].voter_address.length++] = _voter;

        if (Proposals[vote_id].total_weight >= Proposals[vote_id].threshold) {
            Proposals[vote_id].executed = true;
        }
        return true;
    }

    function voteClose() onlyOwner public {
        if (Proposals.length >= 1) {
            Proposals[vote_id].executed = true;
            ProposalEnd(vote_id, Proposals[vote_id].descript);
        }
    }

    function checkVote() onlyOwner public {
        if ((Proposals.length >= 1) &&
            (Proposals[vote_id].end_timestamp < now)) {
            voteClose();
        }
    }
}

contract FreezeToken is owned {
    mapping (address => uint256) public freezeDateOf;

    event Freeze(address indexed _who, uint256 _date);
    event Melt(address indexed _who);

    function checkFreeze(address _sender) public constant returns (bool) {
        if (now >= freezeDateOf[_sender]) {
            return false;
        } else {
            return true;
        }
    }

    function freezeTo(address _who, uint256 _date) internal {
        freezeDateOf[_who] = _date;
        Freeze(_who, _date);
    }

    function meltNow(address _who) internal onlyOwner {
        freezeDateOf[_who] = now;
        Melt(_who);
    }
}

contract TokenInfo is owned {
    using SafeMath for uint256;

    address public token_wallet_address;

    string public name = "MOBIST";
    string public symbol = "MITX";
    uint256 public decimals = 18;
    uint256 public total_supply = 10000000000 * (10 ** uint256(decimals));

    // 1 ether : 10,000 token
    uint256 public conversion_rate = 10;

    event ChangeTokenName(address indexed who);
    event ChangeTokenSymbol(address indexed who);
    event ChangeTokenWalletAddress(address indexed from, address indexed to);
    event ChangeTotalSupply(uint256 indexed from, uint256 indexed to);
    event ChangeConversionRate(uint256 indexed from, uint256 indexed to);
    event ChangeFreezeTime(uint256 indexed from, uint256 indexed to);

    function totalSupply() public constant returns (uint) {
        return total_supply;
    }

    function changeTokenName(string newName) onlyOwner public {
        name = newName;
        ChangeTokenName(msg.sender);
    }

    function changeTokenSymbol(string newSymbol) onlyOwner public {
        symbol = newSymbol;
        ChangeTokenSymbol(msg.sender);
    }

    function changeTokenWallet(address newTokenWallet) onlyOwner internal {
        require(newTokenWallet != address(0));
        address pre_address = token_wallet_address;
        token_wallet_address = newTokenWallet;
        ChangeTokenWalletAddress(pre_address, token_wallet_address);
    }

    function changeTotalSupply(uint256 _total_supply) onlyOwner internal {
        require(_total_supply > 0);
        uint256 pre_total_supply = total_supply;
        total_supply = _total_supply;
        ChangeTotalSupply(pre_total_supply, total_supply);
    }

    function changeConversionRate(uint256 _conversion_rate) onlyOwner public {
        require(_conversion_rate > 0);
        uint256 pre_conversion_rate = conversion_rate;
        conversion_rate = _conversion_rate;
        ChangeConversionRate(pre_conversion_rate, conversion_rate);
    }
}

contract Token is owned, PreSale, FreezeToken, TokenInfo, Vote, BasicToken {
    using SafeMath for uint256;

    bool public open_free = false;

    event Payable(address indexed who, uint256 eth_amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);

    function Token (address _owner_address, address _token_wallet_address) public {
        require(_token_wallet_address != address(0));

        if (_owner_address != address(0)) {
            owner = _owner_address;
            balance_of[owner] = 0;
        } else {
            owner = msg.sender;
            balance_of[owner] = 0;
        }

        token_wallet_address = _token_wallet_address;
        balance_of[token_wallet_address] = total_supply;
    }

    function mintToken(
        address to,
        uint256 token_amount,
        uint256 freeze_timestamp
    ) onlyOwner public returns (bool) {
        require(token_amount > 0);
        require(balance_of[token_wallet_address] >= token_amount);
        require(balance_of[to] + token_amount > balance_of[to]);
        uint256 token_plus_bonus = 0;
        uint sale_number = 0;

        var(sale_info, isSale) = nowSaleInfo();
        if (isSale) {
            sale_number = sale_info.sale_number;
            uint8 bonus_rate = sale_info.bonus_rate;
            token_plus_bonus = addBonus(token_amount, bonus_rate);
            require(checkSaleCanSell(sale_number, token_plus_bonus) == true);
            addSaleSold(sale_number, token_plus_bonus);
        } else if (open_free) {
            token_plus_bonus = token_amount;
        } else {
            require(open_free == true);
        }

        balance_of[token_wallet_address] -= token_plus_bonus;
        balance_of[to] += token_plus_bonus;

        uint256 _freeze = 0;
        if (freeze_timestamp >= 0) {
            _freeze = freeze_timestamp;
        }

        freezeTo(to, now + _freeze); // FreezeToken.sol
        Transfer(0x0, to, token_plus_bonus);
        addAddress(to);
        return true;
    }

    function mintTokenBulk(address[] _tos, uint256[] _amounts) onlyOwner public {
        require(_tos.length == _amounts.length);
        for (uint i=0; i < _tos.length; i++) {
            mintToken(_tos[i], _amounts[i], 0);
        }
    }

    function superMint(
        address to,
        uint256 token_amount,
        uint256 freeze_timestamp
    ) onlyOwner public returns(bool) {
        require(token_amount > 0);
        require(balance_of[token_wallet_address] >= token_amount);
        require(balance_of[to] + token_amount > balance_of[to]);

        balance_of[token_wallet_address] -= token_amount;
        balance_of[to] += token_amount;

        uint256 _freeze = 0;
        if (freeze_timestamp >= 0) {
            _freeze = freeze_timestamp;
        }

        freezeTo(to, now + _freeze);
        Transfer(0x0, to, token_amount);
        Mint(to, token_amount);
        addAddress(to);
        return true;
    }

    function superMintBulk(address[] _tos, uint256[] _amounts) onlyOwner public {
        require(_tos.length == _amounts.length);
        for (uint i=0; i < _tos.length; i++) {
            superMint(_tos[i], _amounts[i], 0);
        }
    }

    function transfer(address to, uint256 value) public {
        _transfer(msg.sender, to, value);
    }

    function transferBulk(address[] tos, uint256[] values) public {
        require(tos.length == values.length);
        for (uint i=0; i < tos.length; i++) {
            transfer(tos[i], values[i]);
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public {
        require(msg.sender != address(0));
        require(_from != address(0));
        require(_amount <= allowances[_from][msg.sender]);
        _transfer(_from, _to, _amount);
        allowances[_from][msg.sender] -= _amount;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) private {
        require(_from != address(0));
        require(_to != address(0));
        require(balance_of[_from] >= _amount);
        require(balance_of[_to].add(_amount) >= balance_of[_to]);
        require(transfer_close == false);
        require(checkFreeze(_from) == false);

        uint256 prevBalance = balance_of[_from] + balance_of[_to];
        balance_of[_from] -= _amount;
        balance_of[_to] += _amount;
        assert(balance_of[_from] + balance_of[_to] == prevBalance);
        addAddress(_to);
        Transfer(_from, _to, _amount);
    }

    function burn(address _who, uint256 _amount) onlyOwner public returns(bool) {
        require(_amount > 0);
        require(balanceOf(_who) >= _amount);
        balance_of[_who] -= _amount;
        total_supply -= _amount;
        Burn(_who, _amount);
        return true;
    }

    function additionalTotalSupply(uint256 _addition) onlyOwner public returns(bool) {
        require(_addition > 0);
        uint256 change_total_supply = total_supply.add(_addition);
        balance_of[token_wallet_address] += _addition;
        changeTotalSupply(change_total_supply);
    }

    function tokenWalletChange(address newTokenWallet) onlyOwner public returns(bool) {
        require(newTokenWallet != address(0));
        uint256 token_wallet_amount = balance_of[token_wallet_address];
        balance_of[newTokenWallet] = token_wallet_amount;
        balance_of[token_wallet_address] = 0;
        changeTokenWallet(newTokenWallet);
    }

    function () payable public {
        uint256 eth_amount = msg.value;
        msg.sender.transfer(eth_amount);
        Payable(msg.sender, eth_amount);
    }

    function tokenOpen() onlyOwner public {
        open_free = true;
    }

    function tokenClose() onlyOwner public {
        open_free = false;
    }

    function freezeAddress(
        address _who,
        uint256 _addTimestamp
    ) onlyOwner public returns(bool) {
        freezeTo(_who, _addTimestamp);
        return true;
    }

    function meltAddress(
        address _who
    ) onlyOwner public returns(bool) {
        meltNow(_who);
        return true;
    }

    // call a voting in Vote.sol
    function voteAgree() public returns (bool) {
        address _voter = msg.sender;
        uint256 _balance = balanceOf(_voter);
        require(_balance > 0);
        return voting(_voter, _balance);
    }

    function superVoteAgree(address who) onlyOwner public returns(bool) {
        require(who != address(0));
        uint256 _balance = balanceOf(who);
        require(_balance > 0);
        return voting(who, _balance);
    }
}