# frozen_string_literal: true

RSpec.describe "Abstracta interface introspection" do
  it "reports direct and inherited interfaces separately" do
    first = Module.new { include Abstracta.interface(:first) }
    second = Module.new { include Abstracta.interface(:second) }

    base = Class.new do
      include Abstracta

      implements first
    end

    child = Class.new(base) do
      implements second
    end

    expect(base.direct_interfaces).to eq([first])
    expect(child.direct_interfaces).to eq([second])
    expect(child.interfaces).to eq([first, second])
  end

  it "merges abstract and interface requirements for validation" do
    interface = Module.new { include Abstracta.interface(:from_interface) }

    base = Class.new do
      include Abstracta.with_methods(:from_abstract_class)
    end

    child = Class.new(base) do
      implements interface
    end

    expect(child.missing_abstract_methods).to eq([:from_abstract_class])
    expect(child.missing_interface_methods).to eq([:from_interface])
    expect(child.missing_methods).to contain_exactly(:from_abstract_class, :from_interface)

    expect { child.validate_implementation! }
      .to raise_error(Abstracta::Error, /#from_abstract_class.*#from_interface/)
  end
end
