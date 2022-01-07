/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

pragma solidity ^0.4.0;

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
    
    //開根號
    function sqrt(uint x) internal pure returns(uint) {
        uint z = (x + 1 ) / 2;
        uint y = x;
        while(z < y){
          y = z;
          z = ( x / z + z ) / 2;
        }
        return y;
     }
}

library Counters {
    using SafeMath for uint256;

    struct Counter {

        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

interface ERC20 {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _owner) external view returns (uint256 balance);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
}

interface ERC721 {

    function owner() external view returns (address);//合約的創建者
    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;

    function GRT_NFT_PRICE(uint256 tokenId) public view returns (uint256 price);
    function GRT_NFT_APY(uint256 tokenId) public view returns (uint256 apy);
    function GRT_NFT_TYPE(uint256 tokenId) public view returns (uint256 _type);
}

contract Staking{
    using SafeMath for uint256;

    ERC20 public JBL_token;
    ERC721 public NFT_token;
    ERC721 public NFT_token2;
    ERC721 public NFT_token3;

    address public contract_owner;
    uint256 public decimals = 18;

    struct Order {
        address nft_addr;
        uint256 nft_id;
        uint256 nft_type;
        address user_addr;
        uint256 price;
        uint256 apy;
        uint256 start_time;
        uint256 end_time;
        uint256 withdraw_time;//最大贖回時間
    }

    mapping (address => bool) private nft_creator;//認證的NFT
    
    Order[] public Orders;
    mapping (uint256 => address) private user_order;// Order_id => User_addr
    mapping(address => uint256[]) private _OrderList;
    mapping (address => uint256) internal user_profit;//總收益

    // User_addr => Order_id[]
    mapping(address => uint256[]) private NFT_OF;// 外野手 (type=0) 
    mapping(address => uint256[]) private NFT_IF;// 內野手 (type=1)
    mapping(address => uint256[]) private NFT_C;// 捕手 (type=2)
    mapping(address => uint256[]) private NFT_P;// 投手 (type=3)
    mapping(address => uint256[]) private NFT_H;// 打擊手 (type=5)

    event staking(address _user, address _nft_addr, uint _nft_id, uint256 _time, uint256 _order_id, uint256 withdraw_time);
    event redeem(address _user, uint256 _end_time, uint256 _order_id, uint256 _amount);
    event cal(uint256 _order_id, uint256 _nft_amount, uint256 _apy, uint256 _start_time, uint256 _end_time, uint256 _days);
    event cancel(address _user, address _nft_addr, uint _nft_id,  uint256 _order_id, uint256 return_time);
    
    constructor ()  public {
        contract_owner = msg.sender; 
        _set_JBL_TOKEN(0x2148c3ed475fc0a4c70269641e6b76c2a4b8c855);
    }
    
    modifier onlyOwner() {
        require(msg.sender == contract_owner);
        _;
    }
    
    //pay token
    function _set_JBL_TOKEN(address _tokenAddr) internal onlyOwner{
        require(_tokenAddr != 0);
        JBL_token = ERC20(_tokenAddr);
    }
    
    // 質押
    function Staking_NFT(address _nft_addr,uint256 _nft_id) public returns (uint256) {
        NFT_token = ERC721(_nft_addr);
        address c_addr = get_nft_creator(_nft_addr);
        require(NFT_token.ownerOf(_nft_id)==msg.sender,"ERC721: owner query for nonexistent token");
        require(nft_creator[c_addr]==true,"ERC721: The contract is not certified.");

        NFT_token.transferFrom(msg.sender, address(this), _nft_id);

        uint256 _price = NFT_token.GRT_NFT_PRICE(_nft_id);
        uint256 _apy = NFT_token.GRT_NFT_APY(_nft_id);
        uint256 _type = NFT_token.GRT_NFT_TYPE(_nft_id);
        
        uint256 OrderId = Orders.length;
        uint256 insert_time = now;
        uint256 endtime = 0;

        uint256 _type_s = _type % 10; // 屬性:外野內野...
        uint256 withdraw_time;//最大贖回時間
        if(_type > 99)
        {
            uint256 _type_d = _type / 100 ; // 
            withdraw_time = now + (_type_d*30*86400);
        }
        else
        {
            withdraw_time = 9999999999;
            add_array_val(_type_s,msg.sender,OrderId);// 寫入各類型的array
        }

        Orders.push(Order(_nft_addr, _nft_id, _type, msg.sender, _price, _apy, insert_time, endtime, withdraw_time));
        
        user_order[OrderId] = msg.sender;

        _OrderList[msg.sender].push(OrderId);//寫入OrderList

        // 寫入事件
        emit staking(msg.sender, _nft_addr, _nft_id, insert_time, OrderId, withdraw_time);
        
        return OrderId;
    }
    
    // 贖回
    function Redeem_NFT(bool _rNFT, uint256 _order_id) public returns (bool){
        require(user_order[_order_id]==msg.sender,"This order is not own.");
        uint256 _etime = now;
        
        // 取得訂單內容
        Order storage order = Orders[_order_id];
        require(order.end_time==0,"This order is completed.");

        // 利息
        uint256 _amount = 0;
        if(order.nft_type*1 > 99)
        {
            if(order.withdraw_time <= _etime)
            {
                _etime = order.withdraw_time; //贖回時間上限
            }
            _amount = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);

            JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

            //寫入總收益
            user_profit[order.user_addr] = user_profit[order.user_addr].add(_amount);

            // 寫入事件
            emit redeem(msg.sender, _etime, _order_id, _amount);

            if(_rNFT==true) // NFT轉回
            {
                NFT_token = ERC721(order.nft_addr);
                NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回

                // 更新結束時間
                order.end_time = _etime;

                // 從類型的array中移除
                del_array_val(order.nft_type % 10,order.user_addr,_order_id);

                //從user質押中的訂單 移除
                delete_orderList(order.user_addr,_order_id);
            }
            else // 只提取收益
            {
                // 更新質押開始時間
                order.start_time = _etime;
                // 最大贖回時間
                uint256 _type_d = order.nft_type*1 / 100 ; // 
                order.withdraw_time = now + (_type_d*30*86400);
            }
            
            return true;
        }
        else
        {
            Order storage order2;
            Order storage order3;
            uint256 order2_id;
            uint256 order3_id;
            uint256 _amount_0;
            uint256 _amount_1;
            uint256 _amount_2;

            if(order.nft_type % 10 ==0)
            {
                //判斷是否有組合APY
                if(NFT_OF[msg.sender].length >=1 && NFT_IF[msg.sender].length >=1 && NFT_H[msg.sender].length >=1)
                {
                    if(order.nft_type % 10 ==0)
                    {
                        order2 = Orders[NFT_IF[msg.sender][0]];
                        order3 = Orders[NFT_H[msg.sender][0]];

                        order2_id = NFT_IF[msg.sender][0];
                        order3_id = NFT_H[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==1)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_H[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_H[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==5)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_IF[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_IF[msg.sender][0];
                    }

                    if(order.nft_type % 10 ==0 || order.nft_type % 10 ==1 || order.nft_type % 10 ==5)
                    {
                        //APY組合加成 10%
                        order.apy = order.apy + (1*10**17); 
                        order2.apy = order2.apy + (1*10**17); 
                        order3.apy = order3.apy + (1*10**17); 

                        _amount_0 = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                        _amount_1 = cal_amount(order2_id, order2.price, order2.apy, order2.start_time, _etime);
                        _amount_2 = cal_amount(order3_id, order3.price, order3.apy, order3.start_time, _etime);

                        _amount = _amount_0 + _amount_1 + _amount_2;
                        JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                        if(_rNFT==true) // NFT轉回
                        {
                            NFT_token = ERC721(order.nft_addr);
                            NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回

                            NFT_token2 = ERC721(order2.nft_addr);
                            NFT_token2.transferFrom(address(this), order2.user_addr, order2.nft_id);// NFT轉回2

                            NFT_token3 = ERC721(order3.nft_addr);
                            NFT_token3.transferFrom(address(this), order3.user_addr, order3.nft_id);// NFT轉回3

                            // 更新結束時間
                            order.end_time = _etime;
                            order2.end_time = _etime;
                            order3.end_time = _etime;

                            // 從類型的array中移除
                            del_array_val(order.nft_type % 10,order.user_addr,_order_id);
                            del_array_val(order2.nft_type % 10,order2.user_addr,order2_id);
                            del_array_val(order3.nft_type % 10,order3.user_addr,order3_id);

                            //從user質押中的訂單 移除
                            delete_orderList(order.user_addr,_order_id);
                            delete_orderList(order2.user_addr,order2_id);
                            delete_orderList(order3.user_addr,order3_id);
                        }
                        else // 只提取收益
                        {
                            // 更新質押開始時間
                            order.start_time = _etime;
                            order2.start_time = _etime;
                            order3.start_time = _etime;
                        }

                        // 寫入事件
                        emit redeem(msg.sender, _etime, _order_id, _amount_0);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order2_id, _amount_1);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order3_id, _amount_2);//寫入個別的利息

                        //寫入總收益
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_0);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_1);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_2);

                        return true;
                    }
                    
                }
                else if(NFT_P[msg.sender].length >=1 && NFT_C[msg.sender].length >=1 && NFT_OF[msg.sender].length >=1)
                {
                    if(order.nft_type % 10 ==3)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_C[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_C[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==2)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_P[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_P[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==0)
                    {
                        order2 = Orders[NFT_C[msg.sender][0]];
                        order3 = Orders[NFT_P[msg.sender][0]];

                        order2_id = NFT_C[msg.sender][0];
                        order3_id = NFT_P[msg.sender][0];
                    }

                    if(order.nft_type % 10 ==3 || order.nft_type % 10 ==2 || order.nft_type % 10 ==0)
                    {
                        //APY組合加成 10%
                        order.apy = order.apy + (1*10**17); 
                        order2.apy = order2.apy + (1*10**17); 
                        order3.apy = order3.apy + (1*10**17); 

                        _amount_0 = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                        _amount_1 = cal_amount(order2_id, order2.price, order2.apy, order2.start_time, _etime);
                        _amount_2 = cal_amount(order3_id, order3.price, order3.apy, order3.start_time, _etime);

                        _amount = _amount_0 + _amount_1 + _amount_2;
                        JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                        if(_rNFT==true) // NFT轉回
                        {
                            NFT_token = ERC721(order.nft_addr);
                            NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回

                            NFT_token2 = ERC721(order2.nft_addr);
                            NFT_token2.transferFrom(address(this), order2.user_addr, order2.nft_id);// NFT轉回2

                            NFT_token3 = ERC721(order3.nft_addr);
                            NFT_token3.transferFrom(address(this), order3.user_addr, order3.nft_id);// NFT轉回3

                            // 更新結束時間
                            order.end_time = _etime;
                            order2.end_time = _etime;
                            order3.end_time = _etime;

                            // 從類型的array中移除
                            del_array_val(order.nft_type % 10,order.user_addr,_order_id);
                            del_array_val(order2.nft_type % 10,order2.user_addr,order2_id);
                            del_array_val(order3.nft_type % 10,order3.user_addr,order3_id);

                            //從user質押中的訂單 移除
                            delete_orderList(order.user_addr,_order_id);
                            delete_orderList(order2.user_addr,order2_id);
                            delete_orderList(order3.user_addr,order3_id);
                        }
                        else // 只提取收益
                        {
                            // 更新質押開始時間
                            order.start_time = _etime;
                            order2.start_time = _etime;
                            order3.start_time = _etime;
                        }

                        // 寫入事件
                        emit redeem(msg.sender, _etime, _order_id, _amount_0);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order2_id, _amount_1);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order3_id, _amount_2);//寫入個別的利息

                        //寫入總收益
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_0);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_1);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_2);

                        return true;
                    }
                    
                }
                else
                {
                    // "無"組合加成
                    _amount = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                    JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                    if(_rNFT==true) // NFT轉回
                    {
                        NFT_token = ERC721(order.nft_addr);
                        NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回
                        
                        // 更新結束時間
                        order.end_time = _etime;

                        // 從類型的array中移除
                        del_array_val(order.nft_type % 10,order.user_addr,_order_id);

                        //從user質押中的訂單 移除
                        delete_orderList(order.user_addr,_order_id);
                    }
                    else // 只提取收益
                    {
                        // 更新質押開始時間
                        order.start_time = _etime;
                    }

                    // 寫入事件
                    emit redeem(msg.sender, _etime, _order_id, _amount);

                    //寫入總收益
                    user_profit[msg.sender] = user_profit[msg.sender].add(_amount);

                    return true;
                }
            }
            else if(order.nft_type % 10 ==1 || order.nft_type % 10 ==5)
            {
                //判斷是否有組合APY
                if(NFT_OF[msg.sender].length >=1 && NFT_IF[msg.sender].length >=1 && NFT_H[msg.sender].length >=1)
                {
                    if(order.nft_type % 10 ==0)
                    {
                        order2 = Orders[NFT_IF[msg.sender][0]];
                        order3 = Orders[NFT_H[msg.sender][0]];

                        order2_id = NFT_IF[msg.sender][0];
                        order3_id = NFT_H[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==1)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_H[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_H[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==5)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_IF[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_IF[msg.sender][0];
                    }

                    if(order.nft_type % 10 ==0 || order.nft_type % 10 ==1 || order.nft_type % 10 ==5)
                    {
                        //APY組合加成 10%
                        order.apy = order.apy + (1*10**17); 
                        order2.apy = order2.apy + (1*10**17); 
                        order3.apy = order3.apy + (1*10**17); 

                        _amount_0 = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                        _amount_1 = cal_amount(order2_id, order2.price, order2.apy, order2.start_time, _etime);
                        _amount_2 = cal_amount(order3_id, order3.price, order3.apy, order3.start_time, _etime);

                        _amount = _amount_0 + _amount_1 + _amount_2;
                        JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                        if(_rNFT==true) // NFT轉回
                        {
                            NFT_token = ERC721(order.nft_addr);
                            NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回

                            NFT_token2 = ERC721(order2.nft_addr);
                            NFT_token2.transferFrom(address(this), order2.user_addr, order2.nft_id);// NFT轉回2

                            NFT_token3 = ERC721(order3.nft_addr);
                            NFT_token3.transferFrom(address(this), order3.user_addr, order3.nft_id);// NFT轉回3

                            // 更新結束時間
                            order.end_time = _etime;
                            order2.end_time = _etime;
                            order3.end_time = _etime;

                            // 從類型的array中移除
                            del_array_val(order.nft_type % 10,order.user_addr,_order_id);
                            del_array_val(order2.nft_type % 10,order2.user_addr,order2_id);
                            del_array_val(order3.nft_type % 10,order3.user_addr,order3_id);

                            //從user質押中的訂單 移除
                            delete_orderList(order.user_addr,_order_id);
                            delete_orderList(order2.user_addr,order2_id);
                            delete_orderList(order3.user_addr,order3_id);
                        }
                        else // 只提取收益
                        {
                            // 更新質押開始時間
                            order.start_time = _etime;
                            order2.start_time = _etime;
                            order3.start_time = _etime;
                        }

                        // 寫入事件
                        emit redeem(msg.sender, _etime, _order_id, _amount_0);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order2_id, _amount_1);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order3_id, _amount_2);//寫入個別的利息

                        //寫入總收益
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_0);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_1);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_2);

                        return true;
                    }
                    
                }
                else
                {
                    // "無"組合加成
                    _amount = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                    JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                    if(_rNFT==true) // NFT轉回
                    {
                        NFT_token = ERC721(order.nft_addr);
                        NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回
                        
                        // 更新結束時間
                        order.end_time = _etime;

                        // 從類型的array中移除
                        del_array_val(order.nft_type % 10,order.user_addr,_order_id);

                        //從user質押中的訂單 移除
                        delete_orderList(order.user_addr,_order_id);
                    }
                    else // 只提取收益
                    {
                        // 更新質押開始時間
                        order.start_time = _etime;
                    }

                    // 寫入事件
                    emit redeem(msg.sender, _etime, _order_id, _amount);

                    //寫入總收益
                    user_profit[msg.sender] = user_profit[msg.sender].add(_amount);

                    return true;
                }
            }
            else if(order.nft_type % 10 ==2 || order.nft_type % 10 ==3)
            {
                //判斷是否有組合APY
                if(NFT_P[msg.sender].length >=1 && NFT_C[msg.sender].length >=1 && NFT_OF[msg.sender].length >=1)
                {
                    if(order.nft_type % 10 ==3)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_C[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_C[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==2)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_P[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_P[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==0)
                    {
                        order2 = Orders[NFT_C[msg.sender][0]];
                        order3 = Orders[NFT_P[msg.sender][0]];

                        order2_id = NFT_C[msg.sender][0];
                        order3_id = NFT_P[msg.sender][0];
                    }

                    if(order.nft_type % 10 ==3 || order.nft_type % 10 ==2 || order.nft_type % 10 ==0)
                    {
                        //APY組合加成 10%
                        order.apy = order.apy + (1*10**17); 
                        order2.apy = order2.apy + (1*10**17); 
                        order3.apy = order3.apy + (1*10**17); 

                        _amount_0 = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                        _amount_1 = cal_amount(order2_id, order2.price, order2.apy, order2.start_time, _etime);
                        _amount_2 = cal_amount(order3_id, order3.price, order3.apy, order3.start_time, _etime);

                        _amount = _amount_0 + _amount_1 + _amount_2;
                        JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                        if(_rNFT==true) // NFT轉回
                        {
                            NFT_token = ERC721(order.nft_addr);
                            NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回

                            NFT_token2 = ERC721(order2.nft_addr);
                            NFT_token2.transferFrom(address(this), order2.user_addr, order2.nft_id);// NFT轉回2

                            NFT_token3 = ERC721(order3.nft_addr);
                            NFT_token3.transferFrom(address(this), order3.user_addr, order3.nft_id);// NFT轉回3

                            // 更新結束時間
                            order.end_time = _etime;
                            order2.end_time = _etime;
                            order3.end_time = _etime;

                            // 從類型的array中移除
                            del_array_val(order.nft_type % 10,order.user_addr,_order_id);
                            del_array_val(order2.nft_type % 10,order2.user_addr,order2_id);
                            del_array_val(order3.nft_type % 10,order3.user_addr,order3_id);

                            //從user質押中的訂單 移除
                            delete_orderList(order.user_addr,_order_id);
                            delete_orderList(order2.user_addr,order2_id);
                            delete_orderList(order3.user_addr,order3_id);
                        }
                        else // 只提取收益
                        {
                            // 更新質押開始時間
                            order.start_time = _etime;
                            order2.start_time = _etime;
                            order3.start_time = _etime;
                        }

                        // 寫入事件
                        emit redeem(msg.sender, _etime, _order_id, _amount_0);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order2_id, _amount_1);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order3_id, _amount_2);//寫入個別的利息

                        //寫入總收益
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_0);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_1);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_2);

                        return true;
                    }
                    
                }
                else
                {
                    // "無"組合加成
                    _amount = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                    JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                    if(_rNFT==true) // NFT轉回
                    {
                        NFT_token = ERC721(order.nft_addr);
                        NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回
                        
                        // 更新結束時間
                        order.end_time = _etime;

                        // 從類型的array中移除
                        del_array_val(order.nft_type % 10,order.user_addr,_order_id);

                        //從user質押中的訂單 移除
                        delete_orderList(order.user_addr,_order_id);
                    }
                    else // 只提取收益
                    {
                        // 更新質押開始時間
                        order.start_time = _etime;
                    }

                    // 寫入事件
                    emit redeem(msg.sender, _etime, _order_id, _amount);

                    //寫入總收益
                    user_profit[msg.sender] = user_profit[msg.sender].add(_amount);

                    return true;
                }
            }
            else
            {
                // "無"組合加成
                _amount = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                if(_rNFT==true) // NFT轉回
                {
                    NFT_token = ERC721(order.nft_addr);
                    NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回
                    
                    // 更新結束時間
                    order.end_time = _etime;

                    // 從類型的array中移除
                    del_array_val(order.nft_type % 10,order.user_addr,_order_id);

                    //從user質押中的訂單 移除
                    delete_orderList(order.user_addr,_order_id);
                }
                else // 只提取收益
                {
                    // 更新質押開始時間
                    order.start_time = _etime;
                }

                // 寫入事件
                emit redeem(msg.sender, _etime, _order_id, _amount);

                //寫入總收益
                user_profit[msg.sender] = user_profit[msg.sender].add(_amount);

                return true;
            }

        }
        
    }

    // 計算贖回的金額
    function cal_amount(uint256 _order_id, uint256 _nft_amount, uint256 _apy, uint256 _stime, uint256 _etime)internal returns (uint256){
        uint256 _time = _etime - _stime;
        uint256 oneDay = 86400;

        //uint256 _days = _time / oneDay;
        uint256 _days = _time / 60;// 測試
        uint256 amount = (((_nft_amount*_apy))/365)*_days;

        // 寫入事件
        emit cal(_order_id, _nft_amount, _apy, _stime, _etime, _days);

        return amount;

    }

    // 試算贖回的金額
    function estimate(uint256 _order_id)public view returns (uint256){
        Order storage order = Orders[_order_id];
        uint256 _etime = now;
        uint256 _amount = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
        return _amount;
    }

    //堤幣(JBL-token)
    function withdraw() public onlyOwner{
        address contract_addr = address(this);
        uint256 contract_balance = JBL_token.balanceOf(contract_addr);
        JBL_token.transfer(msg.sender, contract_balance);
        
    }

    //取消 (退NFT給擁有者)
    function return_NFT(uint256 _order_id) public onlyOwner{
        Order storage order = Orders[_order_id];

        NFT_token = ERC721(order.nft_addr);
        require(NFT_token.ownerOf(order.nft_id)==address(this),"ERC721: owner query for nonexistent token");
        require(order.end_time==0,"This order is completed.");
        NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回
        
        // 更新結束時間
        order.end_time = 999;

        //從user質押中的訂單 移除
        delete_orderList(order.user_addr,_order_id);

        emit cancel(order.user_addr, order.nft_addr, order.nft_id, _order_id, now);
    }

    //贖回or領取JBL - byOwner
    function Redeem_NFT_byOwner(bool _rNFT, uint256 _order_id) public onlyOwner returns (bool){
        uint256 _etime = now;
        
        // 取得訂單內容
        Order storage order = Orders[_order_id];
        require(order.end_time==0,"This order is completed.");

        // 利息
        uint256 _amount = 0;
        if(order.nft_type*1 > 99)
        {
            if(order.withdraw_time <= _etime)
            {
                _etime = order.withdraw_time; //贖回時間上限
            }
            _amount = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);

            JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

            //寫入總收益
            user_profit[order.user_addr] = user_profit[order.user_addr].add(_amount);

            // 寫入事件
            emit redeem(msg.sender, _etime, _order_id, _amount);

            if(_rNFT==true) // NFT轉回
            {
                NFT_token = ERC721(order.nft_addr);
                NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回

                // 更新結束時間
                order.end_time = _etime;

                // 從類型的array中移除
                del_array_val(order.nft_type % 10,order.user_addr,_order_id);

                //從user質押中的訂單 移除
                delete_orderList(order.user_addr,_order_id);
            }
            else // 只提取收益
            {
                // 更新質押開始時間
                order.start_time = _etime;
                // 最大贖回時間
                uint256 _type_d = order.nft_type*1 / 100 ; // 
                order.withdraw_time = now + (_type_d*30*86400);
            }
            
            return true;
        }
        else
        {
            Order storage order2;
            Order storage order3;
            uint256 order2_id;
            uint256 order3_id;
            uint256 _amount_0;
            uint256 _amount_1;
            uint256 _amount_2;

            if(order.nft_type % 10 ==0)
            {
                //判斷是否有組合APY
                if(NFT_OF[msg.sender].length >=1 && NFT_IF[msg.sender].length >=1 && NFT_H[msg.sender].length >=1)
                {
                    if(order.nft_type % 10 ==0)
                    {
                        order2 = Orders[NFT_IF[msg.sender][0]];
                        order3 = Orders[NFT_H[msg.sender][0]];

                        order2_id = NFT_IF[msg.sender][0];
                        order3_id = NFT_H[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==1)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_H[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_H[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==5)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_IF[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_IF[msg.sender][0];
                    }

                    if(order.nft_type % 10 ==0 || order.nft_type % 10 ==1 || order.nft_type % 10 ==5)
                    {
                        //APY組合加成 10%
                        order.apy = order.apy + (1*10**17); 
                        order2.apy = order2.apy + (1*10**17); 
                        order3.apy = order3.apy + (1*10**17); 

                        _amount_0 = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                        _amount_1 = cal_amount(order2_id, order2.price, order2.apy, order2.start_time, _etime);
                        _amount_2 = cal_amount(order3_id, order3.price, order3.apy, order3.start_time, _etime);

                        _amount = _amount_0 + _amount_1 + _amount_2;
                        JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                        if(_rNFT==true) // NFT轉回
                        {
                            NFT_token = ERC721(order.nft_addr);
                            NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回

                            NFT_token2 = ERC721(order2.nft_addr);
                            NFT_token2.transferFrom(address(this), order2.user_addr, order2.nft_id);// NFT轉回2

                            NFT_token3 = ERC721(order3.nft_addr);
                            NFT_token3.transferFrom(address(this), order3.user_addr, order3.nft_id);// NFT轉回3

                            // 更新結束時間
                            order.end_time = _etime;
                            order2.end_time = _etime;
                            order3.end_time = _etime;

                            // 從類型的array中移除
                            del_array_val(order.nft_type % 10,order.user_addr,_order_id);
                            del_array_val(order2.nft_type % 10,order2.user_addr,order2_id);
                            del_array_val(order3.nft_type % 10,order3.user_addr,order3_id);

                            //從user質押中的訂單 移除
                            delete_orderList(order.user_addr,_order_id);
                            delete_orderList(order2.user_addr,order2_id);
                            delete_orderList(order3.user_addr,order3_id);
                        }
                        else // 只提取收益
                        {
                            // 更新質押開始時間
                            order.start_time = _etime;
                            order2.start_time = _etime;
                            order3.start_time = _etime;
                        }

                        // 寫入事件
                        emit redeem(msg.sender, _etime, _order_id, _amount_0);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order2_id, _amount_1);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order3_id, _amount_2);//寫入個別的利息

                        //寫入總收益
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_0);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_1);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_2);

                        return true;
                    }
                    
                }
                else if(NFT_P[msg.sender].length >=1 && NFT_C[msg.sender].length >=1 && NFT_OF[msg.sender].length >=1)
                {
                    if(order.nft_type % 10 ==3)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_C[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_C[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==2)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_P[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_P[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==0)
                    {
                        order2 = Orders[NFT_C[msg.sender][0]];
                        order3 = Orders[NFT_P[msg.sender][0]];

                        order2_id = NFT_C[msg.sender][0];
                        order3_id = NFT_P[msg.sender][0];
                    }

                    if(order.nft_type % 10 ==3 || order.nft_type % 10 ==2 || order.nft_type % 10 ==0)
                    {
                        //APY組合加成 10%
                        order.apy = order.apy + (1*10**17); 
                        order2.apy = order2.apy + (1*10**17); 
                        order3.apy = order3.apy + (1*10**17); 

                        _amount_0 = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                        _amount_1 = cal_amount(order2_id, order2.price, order2.apy, order2.start_time, _etime);
                        _amount_2 = cal_amount(order3_id, order3.price, order3.apy, order3.start_time, _etime);

                        _amount = _amount_0 + _amount_1 + _amount_2;
                        JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                        if(_rNFT==true) // NFT轉回
                        {
                            NFT_token = ERC721(order.nft_addr);
                            NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回

                            NFT_token2 = ERC721(order2.nft_addr);
                            NFT_token2.transferFrom(address(this), order2.user_addr, order2.nft_id);// NFT轉回2

                            NFT_token3 = ERC721(order3.nft_addr);
                            NFT_token3.transferFrom(address(this), order3.user_addr, order3.nft_id);// NFT轉回3

                            // 更新結束時間
                            order.end_time = _etime;
                            order2.end_time = _etime;
                            order3.end_time = _etime;

                            // 從類型的array中移除
                            del_array_val(order.nft_type % 10,order.user_addr,_order_id);
                            del_array_val(order2.nft_type % 10,order2.user_addr,order2_id);
                            del_array_val(order3.nft_type % 10,order3.user_addr,order3_id);

                            //從user質押中的訂單 移除
                            delete_orderList(order.user_addr,_order_id);
                            delete_orderList(order2.user_addr,order2_id);
                            delete_orderList(order3.user_addr,order3_id);
                        }
                        else // 只提取收益
                        {
                            // 更新質押開始時間
                            order.start_time = _etime;
                            order2.start_time = _etime;
                            order3.start_time = _etime;
                        }

                        // 寫入事件
                        emit redeem(msg.sender, _etime, _order_id, _amount_0);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order2_id, _amount_1);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order3_id, _amount_2);//寫入個別的利息

                        //寫入總收益
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_0);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_1);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_2);

                        return true;
                    }
                    
                }
                else
                {
                    // "無"組合加成
                    _amount = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                    JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                    if(_rNFT==true) // NFT轉回
                    {
                        NFT_token = ERC721(order.nft_addr);
                        NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回
                        
                        // 更新結束時間
                        order.end_time = _etime;

                        // 從類型的array中移除
                        del_array_val(order.nft_type % 10,order.user_addr,_order_id);

                        //從user質押中的訂單 移除
                        delete_orderList(order.user_addr,_order_id);
                    }
                    else // 只提取收益
                    {
                        // 更新質押開始時間
                        order.start_time = _etime;
                    }

                    // 寫入事件
                    emit redeem(msg.sender, _etime, _order_id, _amount);

                    //寫入總收益
                    user_profit[msg.sender] = user_profit[msg.sender].add(_amount);

                    return true;
                }
            }
            else if(order.nft_type % 10 ==1 || order.nft_type % 10 ==5)
            {
                //判斷是否有組合APY
                if(NFT_OF[msg.sender].length >=1 && NFT_IF[msg.sender].length >=1 && NFT_H[msg.sender].length >=1)
                {
                    if(order.nft_type % 10 ==0)
                    {
                        order2 = Orders[NFT_IF[msg.sender][0]];
                        order3 = Orders[NFT_H[msg.sender][0]];

                        order2_id = NFT_IF[msg.sender][0];
                        order3_id = NFT_H[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==1)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_H[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_H[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==5)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_IF[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_IF[msg.sender][0];
                    }

                    if(order.nft_type % 10 ==0 || order.nft_type % 10 ==1 || order.nft_type % 10 ==5)
                    {
                        //APY組合加成 10%
                        order.apy = order.apy + (1*10**17); 
                        order2.apy = order2.apy + (1*10**17); 
                        order3.apy = order3.apy + (1*10**17); 

                        _amount_0 = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                        _amount_1 = cal_amount(order2_id, order2.price, order2.apy, order2.start_time, _etime);
                        _amount_2 = cal_amount(order3_id, order3.price, order3.apy, order3.start_time, _etime);

                        _amount = _amount_0 + _amount_1 + _amount_2;
                        JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                        if(_rNFT==true) // NFT轉回
                        {
                            NFT_token = ERC721(order.nft_addr);
                            NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回

                            NFT_token2 = ERC721(order2.nft_addr);
                            NFT_token2.transferFrom(address(this), order2.user_addr, order2.nft_id);// NFT轉回2

                            NFT_token3 = ERC721(order3.nft_addr);
                            NFT_token3.transferFrom(address(this), order3.user_addr, order3.nft_id);// NFT轉回3

                            // 更新結束時間
                            order.end_time = _etime;
                            order2.end_time = _etime;
                            order3.end_time = _etime;

                            // 從類型的array中移除
                            del_array_val(order.nft_type % 10,order.user_addr,_order_id);
                            del_array_val(order2.nft_type % 10,order2.user_addr,order2_id);
                            del_array_val(order3.nft_type % 10,order3.user_addr,order3_id);

                            //從user質押中的訂單 移除
                            delete_orderList(order.user_addr,_order_id);
                            delete_orderList(order2.user_addr,order2_id);
                            delete_orderList(order3.user_addr,order3_id);
                        }
                        else // 只提取收益
                        {
                            // 更新質押開始時間
                            order.start_time = _etime;
                            order2.start_time = _etime;
                            order3.start_time = _etime;
                        }

                        // 寫入事件
                        emit redeem(msg.sender, _etime, _order_id, _amount_0);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order2_id, _amount_1);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order3_id, _amount_2);//寫入個別的利息

                        //寫入總收益
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_0);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_1);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_2);

                        return true;
                    }
                    
                }
                else
                {
                    // "無"組合加成
                    _amount = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                    JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                    if(_rNFT==true) // NFT轉回
                    {
                        NFT_token = ERC721(order.nft_addr);
                        NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回
                        
                        // 更新結束時間
                        order.end_time = _etime;

                        // 從類型的array中移除
                        del_array_val(order.nft_type % 10,order.user_addr,_order_id);

                        //從user質押中的訂單 移除
                        delete_orderList(order.user_addr,_order_id);
                    }
                    else // 只提取收益
                    {
                        // 更新質押開始時間
                        order.start_time = _etime;
                    }

                    // 寫入事件
                    emit redeem(msg.sender, _etime, _order_id, _amount);

                    //寫入總收益
                    user_profit[msg.sender] = user_profit[msg.sender].add(_amount);

                    return true;
                }
            }
            else if(order.nft_type % 10 ==2 || order.nft_type % 10 ==3)
            {
                //判斷是否有組合APY
                if(NFT_P[msg.sender].length >=1 && NFT_C[msg.sender].length >=1 && NFT_OF[msg.sender].length >=1)
                {
                    if(order.nft_type % 10 ==3)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_C[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_C[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==2)
                    {
                        order2 = Orders[NFT_OF[msg.sender][0]];
                        order3 = Orders[NFT_P[msg.sender][0]];

                        order2_id = NFT_OF[msg.sender][0];
                        order3_id = NFT_P[msg.sender][0];
                    }
                    else if(order.nft_type % 10 ==0)
                    {
                        order2 = Orders[NFT_C[msg.sender][0]];
                        order3 = Orders[NFT_P[msg.sender][0]];

                        order2_id = NFT_C[msg.sender][0];
                        order3_id = NFT_P[msg.sender][0];
                    }

                    if(order.nft_type % 10 ==3 || order.nft_type % 10 ==2 || order.nft_type % 10 ==0)
                    {
                        //APY組合加成 10%
                        order.apy = order.apy + (1*10**17); 
                        order2.apy = order2.apy + (1*10**17); 
                        order3.apy = order3.apy + (1*10**17); 

                        _amount_0 = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                        _amount_1 = cal_amount(order2_id, order2.price, order2.apy, order2.start_time, _etime);
                        _amount_2 = cal_amount(order3_id, order3.price, order3.apy, order3.start_time, _etime);

                        _amount = _amount_0 + _amount_1 + _amount_2;
                        JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                        if(_rNFT==true) // NFT轉回
                        {
                            NFT_token = ERC721(order.nft_addr);
                            NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回

                            NFT_token2 = ERC721(order2.nft_addr);
                            NFT_token2.transferFrom(address(this), order2.user_addr, order2.nft_id);// NFT轉回2

                            NFT_token3 = ERC721(order3.nft_addr);
                            NFT_token3.transferFrom(address(this), order3.user_addr, order3.nft_id);// NFT轉回3

                            // 更新結束時間
                            order.end_time = _etime;
                            order2.end_time = _etime;
                            order3.end_time = _etime;

                            // 從類型的array中移除
                            del_array_val(order.nft_type % 10,order.user_addr,_order_id);
                            del_array_val(order2.nft_type % 10,order2.user_addr,order2_id);
                            del_array_val(order3.nft_type % 10,order3.user_addr,order3_id);

                            //從user質押中的訂單 移除
                            delete_orderList(order.user_addr,_order_id);
                            delete_orderList(order2.user_addr,order2_id);
                            delete_orderList(order3.user_addr,order3_id);
                        }
                        else // 只提取收益
                        {
                            // 更新質押開始時間
                            order.start_time = _etime;
                            order2.start_time = _etime;
                            order3.start_time = _etime;
                        }

                        // 寫入事件
                        emit redeem(msg.sender, _etime, _order_id, _amount_0);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order2_id, _amount_1);//寫入個別的利息
                        emit redeem(msg.sender, _etime, order3_id, _amount_2);//寫入個別的利息

                        //寫入總收益
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_0);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_1);
                        user_profit[msg.sender] = user_profit[msg.sender].add(_amount_2);

                        return true;
                    }
                    
                }
                else
                {
                    // "無"組合加成
                    _amount = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                    JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                    if(_rNFT==true) // NFT轉回
                    {
                        NFT_token = ERC721(order.nft_addr);
                        NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回
                        
                        // 更新結束時間
                        order.end_time = _etime;

                        // 從類型的array中移除
                        del_array_val(order.nft_type % 10,order.user_addr,_order_id);

                        //從user質押中的訂單 移除
                        delete_orderList(order.user_addr,_order_id);
                    }
                    else // 只提取收益
                    {
                        // 更新質押開始時間
                        order.start_time = _etime;
                    }

                    // 寫入事件
                    emit redeem(msg.sender, _etime, _order_id, _amount);

                    //寫入總收益
                    user_profit[msg.sender] = user_profit[msg.sender].add(_amount);

                    return true;
                }
            }
            else
            {
                // "無"組合加成
                _amount = cal_amount(_order_id, order.price, order.apy, order.start_time, _etime);
                JBL_token.transfer(order.user_addr, _amount);// JBL-token 利息

                if(_rNFT==true) // NFT轉回
                {
                    NFT_token = ERC721(order.nft_addr);
                    NFT_token.transferFrom(address(this), order.user_addr, order.nft_id);// NFT轉回
                    
                    // 更新結束時間
                    order.end_time = _etime;

                    // 從類型的array中移除
                    del_array_val(order.nft_type % 10,order.user_addr,_order_id);

                    //從user質押中的訂單 移除
                    delete_orderList(order.user_addr,_order_id);
                }
                else // 只提取收益
                {
                    // 更新質押開始時間
                    order.start_time = _etime;
                }

                // 寫入事件
                emit redeem(msg.sender, _etime, _order_id, _amount);

                //寫入總收益
                user_profit[msg.sender] = user_profit[msg.sender].add(_amount);

                return true;
            }

        }
        
    }

    // user所有訂單(質押中)
    function orderList(address addr) public view returns (uint256[]) {
        return _OrderList[addr];
    }
    // 從user質押中的訂單 移除
    function delete_orderList(address addr,uint256 _tokenid) internal {
    
        for (uint j = 0; j < _OrderList[addr].length; j++) {
            if(_OrderList[addr][j]==_tokenid)
            {
                delete _OrderList[addr][j];
                for (uint i = j; i<_OrderList[addr].length-1; i++){
                    _OrderList[addr][i] = _OrderList[addr][i+1];
                }
                delete _OrderList[addr][_OrderList[addr].length-1];
                _OrderList[addr].length--;
            }
        }
    }

    // 總收益
    function get_profit(address _owner) public view returns (uint256){
        return user_profit[_owner];
    }

    // 增加array某個元素
    function add_array_val(uint256 _t,address addr,uint256 _oid) internal {
        // 0=外野手(OF), 1=內野手(IF), 2=捕手(C), 3=投手(P), 5=打擊手(H)
        uint256[] _ar;
        if(_t==0)
        {
            _ar = NFT_OF[addr];
            _ar.push(_oid);
        }
        else if(_t==1)
        {
            _ar = NFT_IF[addr];
            _ar.push(_oid);
        }
        else if(_t==2)
        {
            _ar = NFT_C[addr];
            _ar.push(_oid);
        }
        else if(_t==3)
        {
            _ar = NFT_P[addr];
            _ar.push(_oid);
        }
        else if(_t==5)
        {
            _ar = NFT_H[addr];
            _ar.push(_oid);
        }


    }

    // 移除array某個元素
    function del_array_val(uint256 _t,address addr,uint256 _oid) internal {
        // 0=外野手(OF), 1=內野手(IF), 2=捕手(C), 3=投手(P), 5=打擊手(H)
        uint256[] _ar;
        if(_t==0)
        {
            _ar = NFT_OF[addr];
        }
        else if(_t==1)
        {
            _ar = NFT_IF[addr];
        }
        else if(_t==2)
        {
            _ar = NFT_C[addr];
        }
        else if(_t==3)
        {
            _ar = NFT_P[addr];
        }
        else if(_t==5)
        {
            _ar = NFT_H[addr];
        }

        if(_t==0 || _t==1 || _t==2 || _t==3 || _t==5)
        {
            for (uint j = 0; j < _ar.length; j++) 
            {
                if(_ar[j]==_oid)
                {
                    delete _ar[j];
                    for (uint i = j; i<_ar.length-1; i++){
                        _ar[i] = _ar[i+1];
                    }
                    delete _ar[_ar.length-1];
                    _ar.length--;
                }
            }
        }
        
    }

    // 設定認證or移除的NFT
    function set_nft_creator(address _addr,bool _type)public onlyOwner{
        nft_creator[_addr] = _type;
    }

    // 取得NFT的創建者
    function get_nft_creator(address _nft_addr) public view returns (address) {
        return ERC721(_nft_addr).owner();
    }

}