/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: GPL-3.0
// 每一个币种，应增加一个Bank
pragma solidity >=0.5.0  <0.9.0;
pragma experimental ABIEncoderV2;
library Balances {
    function move(mapping(address => int256) storage bals, address from, address to, int256 amount) internal {
        require(bals[from] >= amount);
        require(bals[to] + amount >= bals[to]);
        bals[from] -= amount;
        bals[to] += amount;
    }
}
// 保证金
// TODO 如果用户直接向合约地址转入，也应支持其转出。需要制作默认的转入函数
contract Mgn {
    enum EvType {Bal,Mgn}
    address Admin;
    ////////////////////////////////////////
    //余额
    mapping(address => int256) bals;
    using Balances for *;   // 引入库
    // 授权可以用于保证金的金额
    mapping(address => int256) mgns;
    // 有转入保证金的钱包
    address[] private mgnOwns;
    // 空闲的保证金位
    // TODO mgnOwners尚未完成 空闲位置管理
    int64[] mgnSlotsAvail;
    ////////////////////////////////////////
    // bals 相互转移
    event Transfer(address from, address to, int256 remaining);
    event BalUpd(EvType aType,address owner,int256 delta, int256 remaining);
    event BalM2M(address[] srclist, address[] tgtlist, uint256[] amtlist);
    // mgns 保证金变更事件
    event MgnUpds(EvType evType, address[] owner,int256[] delta,int256[]remainings);
    // mgn 保证金变更事件
    event MgnUpd(EvType evType,address owner, int256 delta, int256 remaining);
    // M2MOK
    event EndMgnM2m(string SN,bytes RCodes);

    event EndMgnUpd(string SN,bytes RCodes);
    //用户直接向合约地址转入
    receive () external payable {
      int256 val = int256(msg.value);
      bals[msg.sender] +=val;
      emit BalUpd(EvType.Bal, msg.sender,val,bals[msg.sender]);
    }
    //从合约地址转出.只允许用户自己进行
    //TODO 扣除手续费
    function withdraw(int256 amount) public payable {
       require(amount>0);
       int256 bal = bals[msg.sender];
       require(bal>0);
       int256 nv = (bal - amount);
       if (nv < 0 ) {
          amount = bal;
          nv = 0;
       }
       bals[msg.sender] = nv;
       address payable receiver =payable( msg.sender );
       receiver.transfer(uint256(amount));
       // 是否应关闭此事件
       emit BalUpd(EvType.Bal, msg.sender,-amount,nv);
    }
    //保证金更新，用户可以自己追加保证金.但保证金减少，需要通过Admin进行
    //TODO 手续费?
    function mgnAdd(int256 aDelta) public  payable {
        require(aDelta > 0);
        int256 bal = bals[msg.sender];
        if (bal < aDelta) {
          aDelta = bal;
        }
        require(aDelta > 0);
        int256 mgn = mgns[msg.sender];
        if (mgn == 0 ) {//增加位置
          mgnOwns.push(msg.sender);
        }
        mgn +=aDelta;
        bals[msg.sender] = bal - aDelta;
        mgns[msg.sender] = mgn;
        emit MgnUpd(EvType.Mgn, msg.sender,aDelta,mgn);
    }
    function mgnUpd(string memory aSN,address[] memory aOwners, int256[] memory aDeltas) public payable  {
      require(
//        (msg.sender == Admin) &&
        (aOwners.length == aDeltas.length)
        && (!m2mDone[aSN])
             );
      uint256 sl = aOwners.length;
      bytes memory r = new bytes(sl);
      for (uint256 i = 0;i<sl;i++) {
       address aOwner = aOwners[i];
       int256 aDelta = aDeltas[i];
      int256 mgn = mgns[aOwner];
      int256 mgn2 = mgn + aDelta;
      if (mgn2<0) {
        mgn2 = 0;
        aDelta = mgn2 - mgn;
      }
      int256 bal = bals[aOwner];
      int256 bal2 = bal - aDelta;
      if (bal2 < 0) {
        bal2 = 0;
        aDelta = bal - bal2;
        if (aDelta ==0) {
          continue;
        }
        mgn2 = mgn + aDelta;
      }
      mgns[aOwner] = mgn2;
      bals[aOwner] = bal2;
      emit MgnUpd(EvType.Mgn, aOwner,aDelta,mgn2);  
      r[i] = bytes1(uint8(1));
      }
      emit EndMgnUpd(aSN,r);
    }
    // 获取保证金列表,仅Admin可以查看,用于系统初始化   
    // 这里需要约束最大范围
    function mgnList(uint64 aFrom,uint64 aTo) public view returns (address[] memory rOwners, int256[] memory rMgns,bool rIsEnd) {
//        require(msg.sender == Admin);
        uint64 nActs = uint64( mgnOwns.length - mgnSlotsAvail.length);
        if (aTo >= nActs) {
          aTo = nActs;
          rIsEnd = true;
        }
        uint256 rlen = uint256(aTo - aFrom);
        if (rlen==0) {
          rlen = 1;
        }
        rOwners = new  address[](rlen);
        rMgns = new int256[](rlen);
        uint256 idx = 0;
        uint256 iend = uint256(aTo);
        for (uint256 i = uint256(aFrom);i<iend;i++) {
          rOwners[idx] = mgnOwns[i];
          rMgns[idx] = mgns[mgnOwns[i]];
        }
    }
    // 查询自己的余额,注意只有自己才看得到
    function bal() public view returns (int256 balance) {
        return bals[msg.sender];
    }
    // 查询自己的Mgn,只有自己才看得到
    function mgn() public view returns (int256 margin) {
      return mgns[msg.sender];
    }
    // TODO should turn off this API for review. should remove ?
    function transfer(address to, int256 amount) public payable returns (bool success) {
        bals.move(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    // 此函数的执行过程失败几率是较大的

    // 已提交的mgnm2n事务
    
    mapping(string =>bool) m2mDone;

    function mgnM2m(string memory aSN,address[] memory srcs, address[] memory tgts,uint256[] memory amts,string[] memory mids) public payable {
      //require(msg.sender == Admin);
      uint256 sl = srcs.length;
      uint256 tl = tgts.length;
      uint256 al = amts.length;
      uint256 ml = mids.length;
      require((sl==tl)||(al==ml)||(al==sl));
      require (!m2mDone[aSN]);
/*  
      address[] memory addrs;
      int256[] memory deltas;
      int256[] memory rems;
 */   
      bytes memory r = new bytes(sl);
      for (uint256 i=0;i<sl;i++) {
        string memory mid = mids[i];
     //   if (m2mDone[mid]) {
     //     continue;
     //   }
        int256 amt = int256(amts[i]); 
        address src = srcs[i];
        //require (mgns[src] >= amt); must be checked by offline.
        address tgt = tgts[i];

        int256 s_remain = mgns[src]-amt;
        mgns[src] = s_remain;
        int256 t_remain = mgns[tgt]+amt;
        mgns[tgt] = t_remain;
        m2mDone[mid] = true;

        emit MgnUpd(EvType.Mgn,src,-amt,s_remain);
        emit MgnUpd(EvType.Mgn,tgt, amt,t_remain);
        r[i]=bytes1(uint8(1));
        /*
        addrs.push(srcs[si]);
        deltas.push(-amt);
        rems.push(mgns[srcs[si]]);
        
        addrs.push(tgts[ti]);
        deltas.push(amt);
        rems.push(mgns[tgts[ti]]);
        */
      } 
      emit EndMgnM2m(aSN,r);
//      return;
//      emit MgnUpds(EvType.Mgn,addrs,deltas,rems);
    }
////////////////////////////////////////
    // 服务器地址
    string Url;
    //////////////////////////////////////// 
    //本保证金支持的交易对
    address[] Pairs;
    event PairAdded(address aPair,int256 aIdx);
    function AddPair(address aPair) public returns(bool) {
      for (uint i=0;i<Pairs.length;i++) {
        if (Pairs[i] == aPair) {
        return false;
        }
      }
      Pairs.push(aPair);
      emit PairAdded(aPair,int256(Pairs.length));
      return true;
    }
}