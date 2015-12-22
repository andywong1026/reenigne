class Intel8259PIC : public ISA8BitComponent<Intel8259PIC>
{
public:
    static String typeName() { return "Intel8259PIC"; }
    Intel8259PIC(Component::Type type)
      : ISA8BitComponent(type), _interruptrdy(false), _secondAck(false),
        _state(stateReady), _imr(0xff),
        _irqConnector{this, this, this, this, this, this, this, this}
    {
        for (int i = 0; i < 8; ++i) {
            _irqConnector[i].init(i);
            connector("irq" + decimal(i), &_irqConnector[i]);
        }
    }
    class Connector : public InputConnector<bool>
    {
    public:
        Connector(Intel8259PIC* pic) : InputConnector(pic), _pic(pic) { }
        void init(int i) { _i = i; }
        void setData(Tick t, bool v) { _pic->setIRQ(t, _i, v); }

        Intel8259PIC* _pic;
        int _i;
    };
    void setIRQ(Tick t, int i, bool v)
    {
        // TODO
    }

    void setAddress(UInt32 address) { _address = address & 0x1; }
    void read()
    {
        if (_address == 1) {
            if (_secondAck) {
                set(_interruptnum);
                _secondAck = false;
            }
            else
                set(_imr);
        }
    }
    void write(UInt8 data)
    {
        if (_address == 0) {
            if(data & 0x10) {
                _icw1 = data & 0x0f;
                _state = stateICW2;
            }
        }
        else {
            switch (_state) {
                case stateICW2:
                    _offset = data;
                    _state = stateICW3;
                    break;
                case stateICW3:
                    if ((_icw1 & 1) != 0)
                        _state = stateICW4;
                    else
                        _state = stateReady;
                    break;
                case stateICW4:
                    _icw4 = data;
                    _state = stateReady;
                    break;
                case stateReady:
                    _imr = data;
                    break;
            }
        }
    }
    bool interruptRequest() { return _interruptrdy; }
    void interruptAcknowledge()
    {
        if (!_secondAck)
            _secondAck = true;
        else
            _active = true;
        _interruptrdy = false;
    }

    void requestInterrupt(int line)
    {
        if (_state == stateReady) {
            _interruptnum = line + _offset;
            _interruptrdy = (((~_imr) & (1 << line)) != 0);
            _interrupt = false;
            _secondAck = false;
        }
        else
            _interrupt = false;
    }
private:
    UInt8 _interruptnum;
    enum State
    {
        stateReady,
        stateICW2,
        stateICW3,
        stateICW4,
    } _state;

    bool _interrupt;
    bool _interruptrdy;
    bool _secondAck;

    int _address;
    UInt8 _offset;
    UInt8 _irr;
    UInt8 _imr;
    UInt8 _isr;

    UInt8 _icw1;
    UInt8 _icw4;

    Connector _irqConnector[8];
};