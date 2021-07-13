/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

pragma solidity ^0.4.24;
contract ERC20Interface
{
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack
{
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract plantillaToken is ERC20Interface
{
    struct Cuenta
    {
        address propietario;
        uint tokensVenta;
        uint valorToken;
        uint liquidez;
    }
    Cuenta [] public cuentas;
    mapping( address => uint ) public indiceCuenta;
    mapping( uint => address ) public propietarioCuenta;
        
    function crearCuentas ( address propietario ) public
    {
        uint largo = cuentas.length;
        for( uint indice = 0; indice < largo; indice++ )
            if( cuentas[indice] .propietario == propietario )
                return;
        
        indiceCuenta[ propietario ] = largo;
        propietarioCuenta[ largo ] = propietario;
        cuentas.push( Cuenta( propietario, 0, 0, 0 ) );
    }

    uint liquidez = 0;
    uint contadorTransacciones = 0;
    uint metaDeTransacciones = 500;
    uint porcentajeCobrarLiquidez = 1;

    function agregarLiquidez ( uint tokens ) public
    {
        uint indiceCuent = indiceCuenta[ msg.sender ];
        address propietarioCuent = propietarioCuenta[ indiceCuent ];

        if( balances[ msg.sender ] < tokens || propietarioCuent != msg.sender )
            return;

        balances[ msg.sender ] -= tokens;
        cuentas[ indiceCuent ] .liquidez += tokens;
        liquidez += tokens;
    }

    function retirarLiquidez ( uint tokens ) public
    {
        uint indiceCuent = indiceCuenta[ msg.sender ];
        address propietarioCuent = propietarioCuenta[ indiceCuent ];

        if( propietarioCuent != msg.sender || cuentas[indiceCuent].liquidez < tokens )
            return;

        cuentas[ indiceCuent ] .liquidez -= tokens;
        liquidez -= tokens;
        balances[ msg.sender ] += tokens;
    }

    function cobrarPorcentajeLiquidez ( address direccion ) private
    {
        porcentajeCobrarLiquidez = ( ( liquidez * 10 ) / 100 ) / metaDeTransacciones;
        
        if(porcentajeCobrarLiquidez == 0)
            porcentajeCobrarLiquidez = 1;
            
        if( balances[ direccion ] < porcentajeCobrarLiquidez )
            return;

        balances[ direccion ] -= porcentajeCobrarLiquidez;
        balances[ propietarioContrato ] += porcentajeCobrarLiquidez;

        contadorTransacciones++;
    }

    function recompensasLiquidez () public
    {
        if( balances[ propietarioContrato ] == 0 || contadorTransacciones < metaDeTransacciones )
            return;
            
        contadorTransacciones -= metaDeTransacciones;

        uint largo = cuentas.length;
        for( uint indice = 0; indice < largo; indice++ )
        {
            if(cuentas[ indice ] .liquidez == 0)
                continue;

            if( balances[ propietarioContrato ] == 0 )
                return;

            uint porcentaje = cuentas[ indice ] .liquidez / 100;
            if( porcentaje == 0 )
                porcentaje = 1;

            if( balances[ propietarioContrato ] < porcentaje )
                continue;

            balances[ propietarioContrato ] -= porcentaje;
            balances[ cuentas[ indice ] .propietario ] += porcentaje;
        }
    }
    
    

    function venderTokens ( uint tokens, uint valorToken ) public
    {
        uint indiceCuent = indiceCuenta[ msg.sender ];
        address propietarioCuent = propietarioCuenta[ indiceCuent ];

        if( msg.sender != propietarioCuent || balances[ msg.sender ] < tokens )
            return;

        balances[ msg.sender ] -= tokens;
        cuentas[ indiceCuent ] .tokensVenta += tokens;
        cuentas[ indiceCuent ] .valorToken = valorToken * 1 wei;
    }

    function retirarTokensVenta ( uint tokens ) public
    {
        uint indiceCuent = indiceCuenta[ msg.sender ];
        address propietarioCuent = propietarioCuenta[ indiceCuent ];

        if( msg.sender != propietarioCuent || cuentas[ indiceCuent ] .tokensVenta < tokens )
            return;

        cuentas[ indiceCuent ] .tokensVenta -= tokens;
        balances[ msg.sender ] += tokens;
    }

    function comprarTokens ( uint tokens, uint valorToken ) public payable
    {
        if( msg.value != tokens * ( valorToken * 1 wei ) )
            return;

        uint largo = cuentas.length;
        for( uint indice = 0; indice < largo; indice++ )
        {
            if( cuentas[ indice ] .tokensVenta >= tokens && cuentas[ indice ] .valorToken == valorToken )
            {
                cuentas[ indice ] .propietario .transfer( msg.value );
                cuentas[ indice ] .tokensVenta -= tokens;
                balances[ msg.sender ] += tokens;
                return; 
            }
        }
    }
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    
    address propietarioContrato;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor
    (
        string memory _symbol,
        string memory _name,
        uint8 _decimals,
        uint _TotalSupply,
        address _propietario
    )
    public
    {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        _totalSupply = _TotalSupply;
        balances[_propietario] = _totalSupply;
        emit Transfer(address(0), _propietario, _totalSupply);
        propietarioContrato = _propietario;
    }

    function totalSupply() public constant returns (uint)
    {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance)
    {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success)
    {
        if( balances[msg.sender] < tokens )
            return;
            
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        
        cobrarPorcentajeLiquidez(msg.sender);
        cobrarPorcentajeLiquidez(to);
        
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success)
    {
        if( balances[from] < tokens || allowed[from][msg.sender] < tokens )
            return;
        
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        
        cobrarPorcentajeLiquidez(msg.sender);
        cobrarPorcentajeLiquidez(from);
        cobrarPorcentajeLiquidez(to);
        
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining)
    {
        return allowed[tokenOwner][spender];
    }
    
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
}