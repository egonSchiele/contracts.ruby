RSpec.describe "Contracts:" do
  describe "Attrs:" do
    class Person
      include Contracts::Core
      include Contracts::Attrs
      include Contracts::Builtin

      def initialize(name)
        @name_r = name
        @name_w = name
        @name_rw = name
      end

      attr_reader_with_contract :name_r, String
      attr_writer_with_contract :name_w, String
      attr_accessor_with_contract :name_rw, String
    end

    context "attr_reader_with_contract" do
      it "getting valid type" do
        expect(Person.new("bob").name_r)
          .to(eq("bob"))
      end

      it "getting invalid type" do
        expect { Person.new(1.3).name_r }
          .to(raise_error(ReturnContractError))
      end

      it "setting" do
        expect { Person.new("bob").name_r = "alice" }
          .to(raise_error(NoMethodError))
      end
    end

    context "attr_writer_with_contract" do
      it "getting" do
        expect { Person.new("bob").name_w }
          .to(raise_error(NoMethodError))
      end

      it "setting valid type" do
        expect(Person.new("bob").name_w = "alice")
          .to(eq("alice"))
      end

      it "setting invalid type" do
        expect { Person.new("bob").name_w = 1.2 }
          .to(raise_error(ParamContractError))
      end
    end

    context "attr_accessor_with_contract" do
      it "getting valid type" do
        expect(Person.new("bob").name_rw)
          .to(eq("bob"))
      end

      it "getting invalid type" do
        expect { Person.new(1.2).name_rw }
          .to(raise_error(ReturnContractError))
      end

      it "setting valid type" do
        expect(Person.new("bob").name_rw = "alice")
          .to(eq("alice"))
      end

      it "setting invalid type" do
        expect { Person.new("bob").name_rw = 1.2 }
          .to(raise_error(ParamContractError))
      end
    end
  end
end
