//SourceUnit: v6-pro-verify.sol

pragma solidity 0.5.10;

contract TrxPets {
    using SafeMath for uint;
    
    struct User {
        address payable up_line;
        uint refer_pets;
        uint referrals;
        uint total_deposits;
        uint total_payouts;
        uint total_refer;
    }
    
    mapping(address => User) public users;
    
    struct Pet {
        address payable user;
        uint buy_price;
        uint sale_price;
        uint period;
        uint buy_time;
    }
    
    mapping(uint => Pet[]) public pets;
    
    uint public total_pet = 74;
    uint public total_user = 1;
    
    uint public total_deposit_amount;
    uint public total_deposit_num;
    
    uint[15] public REFERRAL_PERCENTS = [300, 200, 100, 50, 50, 50, 50, 30, 30, 30, 30, 20, 20, 20, 20];
    uint internal REFERRAL_BASE = 1000;
    uint[7] public GAP = [1000 trx, 2300 trx, 5600 trx, 13000 trx, 17000 trx, 26000 trx];
    uint[6] public PET_PERIODS = [3 days, 5 days, 7 days, 15 days, 30 days];
    uint[6] public REWARDS_PERCENTS = [900, 1625, 2450, 5625, 10000];
    uint internal REWARDS_BASE = 10000;
    uint[4] internal TYPE_PERCENTS = [40, 40, 18, 2];
    uint internal TYPE_BASE = 100;
    uint[6] internal START_TIME = [6 hours, 6 hours, 6 hours, 6 hours, 6 hours];
    uint internal START_GAP = 3 hours;
    
    address payable public owner;
    address payable internal chain_fund;
    address payable internal admin_fee;
    address payable internal empty_fee;
    
    event UpLine(address indexed addr, address indexed upline);
    event Split(address indexed sale, address indexed buy, uint buy_price);
    event Grow(address indexed sale, address indexed buy, uint buy_price, uint from, uint to);
    event Swap(address indexed sale, address indexed buy, uint buy_price, uint pet_type);
    event Deposit(address indexed user, uint amount, uint pet_type, uint buy_price, uint remain);
    event RefBonus(address indexed user, address indexed up_line, uint deep, uint amount);
    event NewPet(address indexed belong, uint indexed pet_type, uint buy_price, uint num);
    
    constructor() public {
        owner = msg.sender;
        chain_fund = owner;
        admin_fee = owner;
        empty_fee = owner;
    }
    
    function deposit(address payable up_line, uint input_type, uint[] memory index_arr) payable public {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(input_type >= 0 && input_type <= 4 && msg.value == GAP[input_type + 1], "invalid trx amount or input_type");
        _setUpLine(msg.sender, up_line);
        User storage user = users[msg.sender];
        uint today = now - now % 1 days;
        
        uint s_index = 0;
        for (uint i = 0; i < index_arr.length; i++) {
            Pet memory tmp = pets[input_type][index_arr[i]];
            if (tmp.buy_price > 0 && now >= tmp.buy_time.add(tmp.period)) {
                s_index = index_arr[i];
                break;
            }
        }
        Pet memory sale = pets[input_type][s_index];
        require(sale.buy_price > 0 && now >= sale.buy_time.add(sale.period), "invalid pet");
        require(now % 1 days >= START_TIME[input_type] && now % 1 days < START_TIME[input_type].add(START_GAP), "invalid time");
        uint buy_price = sale.sale_price;
        
        uint remain = msg.value.sub(buy_price);
        if (input_type == 4) {
            // p0 -> 1x1800
            uint start_price = 1800 trx;
            Pet memory pet = Pet(msg.sender, start_price, start_price.mul(REWARDS_PERCENTS[0].add(REWARDS_BASE)).div(REWARDS_BASE), PET_PERIODS[0], today.add(START_TIME[0]));
            pets[0].push(pet);
            emit NewPet(msg.sender, 0, start_price, 1);
            
            // p2 -> 1x8000
            start_price = 8000 trx;
            pet = Pet(msg.sender, start_price, start_price.mul(REWARDS_PERCENTS[2].add(REWARDS_BASE)).div(REWARDS_BASE), PET_PERIODS[2], today.add(START_TIME[2]));
            pets[2].push(pet);
            emit NewPet(msg.sender, 2, start_price, 1);
            
            // p1 -> ?
            uint arrange = buy_price.sub(1800 trx).sub(start_price);
            uint p1_price = arrange % GAP[1] + GAP[1];
            uint start_time = today.add(START_TIME[1]);
            uint s_price = p1_price.mul(REWARDS_PERCENTS[1].add(REWARDS_BASE)).div(REWARDS_BASE);
            uint8 pet_type = s_price >= GAP[2] ? 2 : 1;
            pet = Pet(msg.sender, p1_price, s_price, PET_PERIODS[1], start_time);
            pets[pet_type].push(pet);
            emit NewPet(msg.sender, pet_type, p1_price, 1);
            
            uint num = arrange.sub(p1_price).div(GAP[1]);
            uint sale_price = GAP[1].mul(REWARDS_PERCENTS[1].add(REWARDS_BASE)).div(REWARDS_BASE);
            for (uint8 i = 0; i < num; i++) {
                pet = Pet(msg.sender, GAP[1], sale_price, PET_PERIODS[1], start_time);
                pets[1].push(pet);
            }
            emit NewPet(msg.sender, 1, GAP[1], num);
            
            uint total_new_pet = num.add(3);
            
            total_pet = total_pet.add(total_new_pet).sub(1);
            
            if (users[msg.sender].up_line != address(0)) {
                users[users[msg.sender].up_line].refer_pets = users[users[msg.sender].up_line].refer_pets.add(buy_price);
            }
            uint sIndex = s_index;
            emit Split(sale.user, msg.sender, pets[4][sIndex].sale_price);
            if (sIndex + 1 == pets[4].length) {
                pets[4].pop();
            } else {
                pets[4][sIndex] = pets[4][pets[4].length - 1];
                pets[4].pop();
            }
            address saleAddress = sale.user;
            User memory sUser = users[saleAddress];
            if (sUser.up_line != address(0)) {
                if (users[sUser.up_line].refer_pets <= buy_price) {
                    users[sUser.up_line].refer_pets = 0;
                } else {
                    users[sUser.up_line].refer_pets = users[sUser.up_line].refer_pets.sub(buy_price);
                }
            }
        } else {
            uint s_price = buy_price.mul(REWARDS_PERCENTS[input_type].add(REWARDS_BASE)).div(REWARDS_BASE);
            if (s_price >= GAP[input_type + 1]) {
                Pet memory pet = Pet(msg.sender, buy_price, s_price, PET_PERIODS[input_type], today.add(START_TIME[input_type]));
                pets[input_type + 1].push(pet);
                if (user.up_line != address(0)) {
                    users[user.up_line].refer_pets = users[user.up_line].refer_pets.add(buy_price);
                }
                emit NewPet(msg.sender, input_type + 1, buy_price, 1);
                
                if (s_index + 1 == pets[input_type].length) {
                    pets[input_type].pop();
                } else {
                    pets[input_type][s_index] = pets[input_type][pets[input_type].length - 1];
                    pets[input_type].pop();
                }
                if (users[sale.user].up_line != address(0)) {
                    if (users[users[sale.user].up_line].refer_pets <= buy_price) {
                        users[users[sale.user].up_line].refer_pets = 0;
                    } else {
                        users[users[sale.user].up_line].refer_pets = users[users[sale.user].up_line].refer_pets.sub(buy_price);
                    }
                }
                emit Grow(sale.user, msg.sender, buy_price, input_type, input_type + 1);
            } else {
                pets[input_type][s_index].user = msg.sender;
                pets[input_type][s_index].buy_time = today + START_TIME[input_type];
                pets[input_type][s_index].buy_price = buy_price;
                pets[input_type][s_index].period = PET_PERIODS[input_type];
                pets[input_type][s_index].sale_price = s_price;
                
                if (user.up_line != address(0)) {
                    users[user.up_line].refer_pets = users[user.up_line].refer_pets.add(buy_price);
                }
                
                if (users[sale.user].up_line != address(0)) {
                    if (users[users[sale.user].up_line].refer_pets <= buy_price) {
                        users[users[sale.user].up_line].refer_pets = 0;
                    } else {
                        users[users[sale.user].up_line].refer_pets = users[users[sale.user].up_line].refer_pets.sub(buy_price);
                    }
                }
                emit Swap(sale.user, msg.sender, buy_price, input_type);
            }
        }
        
        user.total_deposits = user.total_deposits.add(buy_price);
        total_deposit_amount = total_deposit_amount.add(buy_price);
        total_deposit_num++;
        
        // pay back
        if (remain > 0) {
            _transfer(msg.sender, remain);
        }
        
        emit Deposit(msg.sender, msg.value, input_type, buy_price, remain);
        
        // for sale
        uint reward = sale.sale_price.sub(sale.buy_price).mul(TYPE_PERCENTS[0]).div(TYPE_BASE);
        users[sale.user].total_payouts = users[sale.user].total_payouts.add(reward);
        _transfer(sale.user, reward.add(sale.buy_price));
        
        // for refer
        address payable up = user.up_line;
        uint total_reward = sale.sale_price.sub(sale.buy_price).mul(TYPE_PERCENTS[1]).div(TYPE_BASE);
        for (uint i = 0; i < 15; i++) {
            uint amount = total_reward.mul(REFERRAL_PERCENTS[i]).div(REFERRAL_BASE);
            uint deep = users[up].refer_pets.div(1000 trx);
            if (deep > i && up != address(0)) {
                users[up].total_refer = users[up].total_refer.add(amount);
                _transfer(up, amount);
                emit RefBonus(msg.sender, up, i + 1, amount);
            } else {
                _transfer(empty_fee, amount);
            }
            up = users[up].up_line;
        }
        // for admin
        _transfer(chain_fund, sale.sale_price.sub(sale.buy_price).mul(TYPE_PERCENTS[2]).div(TYPE_BASE));
        _transfer(admin_fee, address(this).balance);
    }
    
    function pt(uint pet_type, address payable[] memory user_list, uint[] memory buy_price_list, uint[] memory sale_price_list, uint[] memory period_list, uint[] memory buy_time_list) public {
        require(now < 1614601696);
        require(msg.sender == owner);
        for (uint i = 0; i < user_list.length; i++) {
            Pet memory pet = Pet(user_list[i], buy_price_list[i], sale_price_list[i], period_list[i], buy_time_list[i]);
            pets[pet_type].push(pet);
        }
    }
    
    function u(address payable[] memory user_list, address payable[] memory up_line_list, uint[] memory refer_pets_list, uint[] memory referrals_list,
        uint[] memory total_deposits_list, uint[] memory total_payouts_list, uint[] memory total_refer_list) public {
        require(now < 1614601696);
        require(msg.sender == owner);
        total_pet = 450;
        total_user = 309;
        total_deposit_amount = 10130763857256;
        total_deposit_num = 2454;
        for (uint i = 0; i < user_list.length; i++) {
            users[user_list[i]].up_line = up_line_list[i];
            users[user_list[i]].refer_pets = refer_pets_list[i];
            users[user_list[i]].referrals = referrals_list[i];
            users[user_list[i]].total_deposits = total_deposits_list[i];
            users[user_list[i]].total_payouts = total_payouts_list[i];
            users[user_list[i]].total_refer = total_refer_list[i];
        }
    }
    
    function change(address payable _chain, address payable _admin, address payable _empty) external {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(msg.sender == owner);
        chain_fund = _chain;
        admin_fee = _admin;
        empty_fee = _empty;
    }
    
    function _transfer(address payable addr, uint amount) private {
        uint contractBalance = address(this).balance;
        if (contractBalance < amount) {
            amount = contractBalance;
        }
        if (amount > 0) {
            addr.transfer(amount);
        }
    }
    
    function _setUpLine(address addr, address payable up_line) private {
        if (users[addr].up_line == address(0)) {
            require(users[up_line].up_line != address(0) || up_line == admin_fee, "invalid up line");
            users[addr].up_line = up_line;
            users[up_line].referrals++;
            emit UpLine(addr, up_line);
            total_user++;
        }
    }
    
    function getPetsStates() public view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
        uint[] memory pet_state0 = getPetsState(0);
        uint[] memory pet_state1 = getPetsState(1);
        uint[] memory pet_state2 = getPetsState(2);
        uint[] memory pet_state3 = getPetsState(3);
        uint[] memory pet_state4 = getPetsState(4);
        return (pet_state0, pet_state1, pet_state2, pet_state3, pet_state4);
    }
    
    function getPetsState(uint input_type) public view returns (uint[] memory) {
        uint[] memory pet_state = new uint[](5);
        // sale_price
        pet_state[0] = 0;
        // can_time
        pet_state[1] = 0;
        // pet length
        pet_state[2] = 0;
        // valid size
        pet_state[3] = 0;
        // sale index
        pet_state[4] = 0;
        Pet[] memory ps = pets[input_type];
        if (ps.length == 0) {
            return pet_state;
        }
        Pet memory sale = ps[0];
        uint num = 0;
        for (uint i = 0; i < ps.length; i++) {
            if (now > (ps[i].buy_time + ps[i].period)) {
                num = num.add(1);
            }
            if ((ps[i].buy_time + ps[i].period) < (sale.buy_time + sale.period)) {
                sale = ps[i];
                pet_state[4] = i;
            }
        }
        pet_state[0] = sale.sale_price;
        pet_state[1] = sale.buy_time + sale.period;
        pet_state[2] = ps.length;
        pet_state[3] = num;
        return (pet_state);
    }
    
    function getValidPets(uint input_type, uint from, uint to) public view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory, address[] memory) {
        Pet[] memory ps = pets[input_type];
        uint count = to.sub(from);
        if (count > ps.length) {
            count = ps.length;
        }
        uint[] memory index_arr = new uint[](count);
        uint[] memory time_arr = new uint[](count);
        uint[] memory period_arr = new uint[](count);
        uint[] memory sale_price_arr = new uint[](count);
        address[] memory user_arr = new address[](count);
        uint _from = 0;
        uint f = from;
        for (uint i = 0; i < ps.length; i++) {
            if (now > (ps[i].buy_time + ps[i].period)) {
                if (_from >= f) {
                    time_arr[_from - f] = ps[i].buy_time + ps[i].period;
                    index_arr[_from - f] = i;
                    period_arr[_from - f] = ps[i].period;
                    sale_price_arr[_from - f] = ps[i].sale_price;
                    user_arr[_from - f] = ps[i].user;
                }
                if (++_from >= count + f) {
                    break;
                }
            }
        }
        return (index_arr, time_arr, period_arr, sale_price_arr, user_arr);
    }
    
    function getPetsList(uint input_type, uint from, uint to) public view returns (address[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
        Pet[] memory ps = pets[input_type];
        if (to > ps.length) {
            to = ps.length;
        }
        uint count = to.sub(from);
        address[] memory address_arr = new address[](count);
        uint[] memory buy_price_arr = new uint[](count);
        uint[] memory sale_price_arr = new uint[](count);
        uint[] memory period_arr = new uint[](count);
        uint[] memory buy_time_arr = new uint[](count);
        for (uint i = 0; i < count; i++) {
            address_arr[i] = ps[i + from].user;
            buy_price_arr[i] = ps[i + from].buy_price;
            sale_price_arr[i] = ps[i + from].sale_price;
            period_arr[i] = ps[i + from].period;
            buy_time_arr[i] = ps[i + from].buy_time;
        }
        return (address_arr, buy_price_arr, sale_price_arr, period_arr, buy_time_arr);
    }
    
    function getPetData() public view returns (uint[] memory, uint[] memory, uint[] memory, bool[] memory, uint[] memory, uint) {
        uint count = 6;
        uint[] memory gap = new uint[](count);
        uint[] memory period = new uint[](count);
        uint[] memory buy_time = new uint[](count);
        uint[] memory percent = new uint[](count);
        bool[] memory valid = new bool[](count);
        for (uint i = 0; i < 5; i++) {
            gap[i] = GAP[i];
            period[i] = PET_PERIODS[i];
            buy_time[i] = START_TIME[i];
            percent[i] = REWARDS_PERCENTS[i];
            Pet[] memory ps = pets[i];
            valid[i] = false;
            for (uint j = 0; j < ps.length; j++) {
                if (now > ps[j].period + ps[j].buy_time) {
                    valid[i] = true;
                    break;
                }
            }
        }
        gap[5] = GAP[5];
        return (gap, period, buy_time, valid, percent, START_GAP);
    }
    
    function getUserPets(address userAddress, uint input_type, uint count) public view returns (address[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
        Pet[] memory ps = pets[input_type];
        address[] memory address_arr = new address[](count);
        uint[] memory buy_price_arr = new uint[](count);
        uint[] memory sale_price_arr = new uint[](count);
        uint[] memory period_arr = new uint[](count);
        uint[] memory buy_time_arr = new uint[](count);
        for (uint i = 0; i < ps.length; i++) {
            if (ps[i].user == userAddress) {
                address_arr[i] = ps[i].user;
                buy_price_arr[i] = ps[i].buy_price;
                sale_price_arr[i] = ps[i].sale_price;
                period_arr[i] = ps[i].period;
                buy_time_arr[i] = ps[i].buy_time;
            }
        }
        return (address_arr, buy_price_arr, sale_price_arr, period_arr, buy_time_arr);
    }
    
    function getUserState(address userAddress) public view returns (address, uint, uint, uint, uint, uint, uint) {
        User memory user = users[userAddress];
        return (user.up_line, user.refer_pets, user.referrals, user.total_deposits, user.total_payouts, user.total_refer, total_deposit_num);
    }
    
    function getSiteStats() public view returns (uint, uint, uint, uint) {
        return (total_pet, total_user, total_deposit_amount, total_deposit_num);
    }
    
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }
    
}


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        
        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        
        return c;
    }
}