pragma solidity ^0.4.18;


contract DI {
    function ap(address u_) external;
    function rb(address u_) external;
    function ico(uint i_, address x_, uint c_) external;
    function sco(uint i_, address x_, uint c_) external;
    function gco(uint i_, address x_) public view returns (uint _c);
    function gcp(uint ci_) public view returns (uint _c);
    function cpn(uint ci_) external;
    function gur(address x_, address y_) external returns (address _z);
    function gcmp(uint i_, uint c_) public view returns (uint _c);
    function cmpn(uint i_, uint c_) external;
    function cg(address x_, uint gpc_, uint mg_, uint gc_) external;
    function ggc(address x_) public view returns (uint _c);
    function ggcd(address x_) public view returns (uint _c);
    function guhb(address x_) public view returns (bool _c);
    function gcsc(uint ci_) public view returns (uint _c);
    function gcpn(uint ci_) public view returns (uint _c);
    function gcpm(uint ci_) public view returns (uint _c);
    function gcpa(uint ci_) public view returns (uint _c);
    function gcsp(uint ci_) public view returns (uint _c);
    function sc(uint ci_, uint csp_, uint cpm_, uint cpa_, uint csc_) external;
    function irbg(address x_, uint c_) external;
    function grg(address x_) public view returns (uint _c);
}

contract Presale {
    event EventBc(address x_, uint ci_);
    event EventBmc(address x_, uint ci_, uint c_);
    event EventCg(address x_);

    uint rb = 10;
    uint GC = 10;
    uint MG = 50;
    uint GPC = 3;
    uint npb = 50;

    DI di;
    address public opAddr;
    address private newOpAddr;

    function Presale() public {
        opAddr = msg.sender;
    }


    function bc(uint ci_, address ref_) public payable {
        uint cp_ = di.gcp(ci_);
        require(cp_ > 0);
        cp_ = cp_ * pf(msg.sender)/10000;
        require(msg.value >= cp_);

        uint excessMoney = msg.value - cp_;

        di.cpn(ci_);
        di.ico(ci_, msg.sender, 1);

        di.ap(msg.sender);
        di.rb(msg.sender);

        EventBc(msg.sender, ci_);

        address rr = di.gur(msg.sender, ref_);
        if(rr != address(0))
            rr.transfer(cp_ * rb / 100);

        msg.sender.transfer(excessMoney);
    }

    function bmc(uint ci_, uint c_, address ref_) public payable {
        require(di.gcp(ci_) > 0);

        uint cmp_ = di.gcmp(ci_, c_);
        cmp_ = cmp_ * pf(msg.sender)/10000;
        require(msg.value >= cmp_);

        uint excessMoney = msg.value - cmp_;
            


        di.cmpn(ci_, c_);
        di.ico(ci_, msg.sender, c_);

        di.ap(msg.sender);
        di.rb(msg.sender);

        EventBmc(msg.sender, ci_, c_);

        address rr = di.gur(msg.sender, ref_);
        if(rr != address(0)) {
            uint rrb = cmp_ * rb / 100;
            di.irbg(rr, rrb);
            rr.transfer(rrb);
        }
        msg.sender.transfer(excessMoney);
    }
    
    function cg() public {
        di.cg(msg.sender, GPC, MG, GC);
        di.ap(msg.sender);
        EventCg(msg.sender);
    }

    function pf(address u_) public view returns (uint c) {
        c = 10000;
        if(!di.guhb(u_)) {
            c = c * (100 - npb) / 100;
        }
        uint _gc = di.ggc(u_);
        if(_gc > 0) {
            c = c * (100 - _gc) / 100;
        }
    }

    function cd1(address x_) public view returns (uint _gc, uint _gcd, bool _uhb, uint _npb, uint _ggcd, uint _mg, uint _gpc, uint _rb, uint _rg) {
        _gc = di.ggc(x_);
        _gcd = di.ggcd(x_);
        _uhb = di.guhb(x_);
        _npb = npb;
        _ggcd = GC;
        _mg = MG;
        _gpc = GPC;
        _rb = rb;
        _rg = di.grg(x_);
    }
    function cd() public view returns (uint _gc, uint _gcd, bool _uhb, uint _npb, uint _ggcd, uint _mg, uint _gpc, uint _rb, uint _rg) {
        return cd1(msg.sender);
    }
    function gcard(uint ci_, address co_) public view returns (uint _coc, uint _csc, uint _cp, uint _cpn, uint _cpm, uint _cpa, uint _csp) {
        _coc = di.gco(ci_, co_);
        _csc = di.gcsc(ci_);
        _cp = di.gcp(ci_);
        _cpn = di.gcpn(ci_);
        _cpm = di.gcpm(ci_);
        _cpa = di.gcpa(ci_);
        _csp = di.gcsp(ci_);
    }


    function sc(uint ci_, uint csp_, uint cpm_, uint cpa_, uint csc_) public onlyOp {
        di.sc(ci_, csp_, cpm_, cpa_, csc_);
    }
    function srb(uint rb_) external onlyOp {
        rb = rb_;
    }
    function sgc(uint GC_) public onlyOp {
        GC = GC_;
    }
    function smg(uint MG_) public onlyOp {
        MG = MG_;
    }   
    function sgpc(uint GPC_) public onlyOp {
        GPC = GPC_;
    }    
    function snpb(uint npb_) public onlyOp {
        npb = npb_;
    }

    function payout(address to_) public onlyOp {
        payoutX(to_, this.balance);
    }
    function payoutX(address to_, uint value_) public onlyOp {
        require(address(0) != to_);
        if(value_ > this.balance)
            to_.transfer(this.balance);
        else
            to_.transfer(value_);
    }

    function sdc(address dc_) public onlyOp {
        if(dc_ != address(0))
            di = DI(dc_);
    }
    modifier onlyOp() {
        require(msg.sender == opAddr);
        _;
    }
    function setOp(address newOpAddr_) public onlyOp {
        require(newOpAddr_ != address(0));
        newOpAddr = newOpAddr_;
    }
    function acceptOp() public {
        require(msg.sender == newOpAddr);
        require(address(0) != newOpAddr);
        opAddr = newOpAddr;
        newOpAddr = address(0);
    }
}