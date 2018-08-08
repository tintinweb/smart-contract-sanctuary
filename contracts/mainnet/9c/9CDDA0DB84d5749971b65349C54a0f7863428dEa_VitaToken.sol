pragma solidity ^0.4.18;
// Symbol      : VTA
// Name        : Vita Token
// Total supply: 10 ** 28
// Decimals    : 18
//import &#39;./SafeMath.sol&#39;;
//import &#39;./ERC20Interface.sol&#39;;
//Sobre vita reward:
//El token se crea primero y luego se asigna la direcci&#243;n de vita reward

// ----- Safe Math
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
//------------
// ----- ERC20Interface
contract ERC20Interface {
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
//------------

contract VitaToken is ERC20Interface, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    address public manager;
    address public reward_contract;
    uint public crowd_start_date;
    uint public crowd_end_date;
    uint public first_bonus_duration;
    uint public second_bonus_duration;
    uint public extra_bonus_duration;
    //uint public third_bonus_duration;
    uint public first_bonus_amount;
    uint public second_bonus_amount;
    uint public third_bonus_amount;
    uint public extra_bonus_amount;
    uint public ETH_VTA;
    uint public total_reward_amount;
    uint public max_crowd_vitas;
    uint public collected_crowd_vitas;
    //Cantidad total recaudada en wei
    uint public collected_crowd_wei;

    mapping(address => uint) balances;
    mapping(address => uint) rewards;
    mapping(address => mapping(address => uint)) allowed;
    function VitaToken() public {
        symbol = "VTA";
        name = "Vita Token";
        //Razones para usar la cantidad estandar de decimales:
        //Todos los envios de dinero se hacen con wei, que es 1 seguido de 18 ceros
        //Seguir el estandar facilita los calculos, especialmente en el crowdsale
        //
        decimals = 18;
        ETH_VTA = 100000;
        //Weis recaudados en crowdsale
        collected_crowd_wei = 0;
        //3 mil millones mas 18 decimales
        max_crowd_vitas = 3 * 10 ** 27;
        //Vitas recaudadas en crowdsale
        collected_crowd_vitas = 0;
        // 10 mil millones m&#225;s 18 decimales
        totalSupply = 10 ** 28;
        manager = msg.sender;
        //Mitad para reward, mitad para el equipo
        total_reward_amount = totalSupply / 2;
        balances[manager] = totalSupply / 2;

        crowd_start_date = now;
        extra_bonus_duration = 4 days;
        //El crowdsale termina 122 d&#237;as de lanzar el SC (15 agosto)
        crowd_end_date = crowd_start_date + extra_bonus_duration + 122 days;
        //la duraci&#243;n del primer bono es de 47 d&#237;as (15 de abril - 1 de junio)
        first_bonus_duration = 47 days;
        //la duraci&#243;n del segundo bono es de 30 d&#237;as (1 de junio - 1 de julio)
        second_bonus_duration = 30 days;
        //la duraci&#243;n del tercer bono es de 45 d&#237;as, no es relevante agregarla porque es el caso final (1 de julio - 15 de agosto)


        extra_bonus_amount = 40000;
        first_bonus_amount = 35000;
        second_bonus_amount = 20000;
        third_bonus_amount = 10000;
    }

    modifier restricted(){
        require(msg.sender == manager);
        _;
    }

    //Decorador para m&#233;todos que solo pueden ser accedidos a trav&#233;s de Vita reward
    modifier onlyVitaReward(){
        require(msg.sender == reward_contract);
        _;
    }
    //Transferir propiedad del contrato
    function transferOwnership(address new_manager) public restricted {
        emit OwnershipTransferred(manager, new_manager);
        manager = new_manager;
    }

    //Cambiar el contrato de Vita reward
    function newVitaReward(address new_reward_contract) public restricted {
        uint amount_to_transfer;
        if(reward_contract == address(0)){
            amount_to_transfer = total_reward_amount;
        }else{
            amount_to_transfer = balances[reward_contract];
        }
        balances[new_reward_contract] = amount_to_transfer;
        balances[reward_contract] = 0;
        reward_contract = new_reward_contract;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function rewardsOf(address _owner) public view returns (uint balance) {
        return rewards[_owner];
    }

    //tokens debe ser el n&#250;mero de tokens seguido del n&#250;mero de decimales
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    //tokens debe ser el n&#250;mero de tokens seguido del n&#250;mero de decimales
    function reward(address patient, address company, uint tokens_patient, uint tokens_company, uint tokens_vita_team) public onlyVitaReward returns (bool success) {
        balances[reward_contract] = safeSub(balances[reward_contract], (tokens_patient + tokens_company + tokens_vita_team));
        //Se envian los tokens del paciente, normalmente el 90%
        balances[patient] = safeAdd(balances[patient], tokens_patient);
        //Se envian los tokens a la compa&#241;ia que hizo la llamada a reward, normalmente 5%
        balances[company] = safeAdd(balances[company], tokens_company);
        //Se envian los tokens al equipo de vita, normalmente 5%
        balances[manager] = safeAdd(balances[manager], tokens_vita_team);
        rewards[patient] = safeAdd(rewards[patient], 1);
        emit Transfer(reward_contract, patient, tokens_patient);
        emit Transfer(reward_contract, company, tokens_company);
        emit Transfer(reward_contract, manager, tokens_vita_team);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(balances[from] >= tokens && allowed[from][msg.sender] >= tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Permite determinar cuantas VTA tiene un usuario permitido gastar
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function () public payable {
        require(now >= crowd_start_date && now <= crowd_end_date);
        require(collected_crowd_vitas < max_crowd_vitas);
        uint tokens;
        if(now <= crowd_start_date + extra_bonus_duration){
            tokens = msg.value * (ETH_VTA + extra_bonus_amount);
        }else if(now <= crowd_start_date + extra_bonus_duration + first_bonus_duration){
            tokens = msg.value * (ETH_VTA + first_bonus_amount);
        }else if(now <= crowd_start_date + extra_bonus_duration + first_bonus_duration + second_bonus_duration){
            tokens = msg.value * (ETH_VTA + second_bonus_amount);
        }else{
            tokens = msg.value * (ETH_VTA + third_bonus_amount);
        }

        balances[manager] = safeSub(balances[manager], tokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        emit Transfer(manager, msg.sender, tokens);
        collected_crowd_wei += msg.value;
        collected_crowd_vitas += tokens;
        manager.transfer(msg.value);
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}