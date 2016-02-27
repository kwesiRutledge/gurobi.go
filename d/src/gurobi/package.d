module gurobi;
public import api_c;

private
{
  import std.stdio;
  import std.c.stdlib;
}

class Env
{
  GRBenv* env;

public:
  this(string logfilename)
  {
    int error = GRBloadenv(&env, cast(char*) logfilename);
    if (error)
      throw new Exception("cannot load environment");
  }

  ~this()
  {
    // Free environment
    GRBfreeenv(env);
  }

  GRBenv* get()
  {
    return env;
  }
}

class Model
{
  GRBmodel* model;

  void failure()
  {
    GRBenv* env = GRBgetenv(model);
    assert(env != null);
    throw new Exception("ERROR: GUROBI");
  }

public:
  this(GRBmodel* model)
  {
    this.model = model;
  }

  this(Env env, string modelname)
  {
    GRBmodel* model;
    int error = GRBnewmodel(env.get(), &model, cast(char*) modelname, 0,
      cast(double*) null, cast(double*) null, cast(double*) null,
      cast(char*) null, cast(char**) null);
    if (error)
      throw new Exception("ERROR: GUROBI");

    this(model);
  }

  ~this()
  {
    // Free model
    GRBfreemodel(model);
  }

  int get_int_attr(string attr)
  {
    int val;
    int error = GRBgetintattr(model, cast(char*) attr, &val);
    if (error)
      failure();
    return val;
  }

  double get_double_attr(string attr)
  {
    double val;
    int error = GRBgetdblattr(model, cast(char*) attr, &val);
    if (error)
      failure();
    return val;
  }

  double[] get_double_attrs(string attr, int length)
  {
    double[] val = new double[length];
    int error = GRBgetdblattrarray(model,
                                   cast(char*) attr,
                                   0,
                                   length,
                                   cast(double*) val);
    if (error)
      failure();
    return val;
  }

  void set_int_attr(string attr, int value)
  {
    int error = GRBsetintattr(model, cast(char*) attr, value);
    if (error)
      failure();
  }

  void add_vars(char[] vtype, double[] obj)
  in
  {
    assert(obj.length == vtype.length);
  }
  body
  {
    int error = GRBaddvars(model,
                           cast(int) obj.length,
                           0,
                           cast(int*) null,
                           cast(int*) null,
                           cast(double*) null,
                           cast(double*) obj,
                           cast(double*) null,
                           cast(double*) null,
                           cast(char*) vtype,
                           cast(char**) null);
    if (error)
      failure();
  }

  void add_vars(char vtype, int length, double[] obj)
  in
  {
    assert(obj.length == length);
  }
  body
  {
    char[] vtypes = new char[length];
    vtypes[] = vtype;
    add_vars(vtypes, obj);
  }

  void add_constr(string cname, int[] ind, double[] val, char sense, double rhs)
  in
  {
    assert(ind.length == val.length);
  }
  body
  {
    int error = GRBaddconstr(model, cast(int) ind.length, cast(int*) ind,
      cast(double*) val, sense, rhs, cast(char*) cname);
    if (error)
      failure();
  }

  void update()
  {
    int error = GRBupdatemodel(model);
    if (error)
      failure();
  }

  void optimize()
  {
    int error = GRBoptimize(model);
    if (error)
      failure();
  }

  void write(string filename)
  {
    int error = GRBwrite(model, cast(char*) filename);
    if (error)
      failure();
  }
}
