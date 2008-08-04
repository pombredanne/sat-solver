/*
 * Solvable
 */

%{

/*
 * iterating over attributes of a (x)solvable ('yield' in Ruby)
 */

static int
xsolvable_each_attr_callback( Solvable *s, Repodata *data, Repokey *key, KeyValue *kv )
{
  static Swig_Type value = Swig_Null;

  /*
   * !! keep the order of case statements according to knownid.h !!
   */
 
  switch( key->type )
    {
      case REPOKEY_TYPE_VOID:
        value = Swig_True;
      break;
      case REPOKEY_TYPE_CONSTANT:
      case REPOKEY_TYPE_NUM:
      case REPOKEY_TYPE_U32:
        value = Swig_Int( key->size );
      break;
      case REPOKEY_TYPE_CONSTANTID:
        value = Swig_Int( key->size );
      break;
      case REPOKEY_TYPE_ID:
        if (data->localpool)
	  value = Swig_String( stringpool_id2str( &data->spool, kv->id ) );
	else
	  value = Swig_String( id2str( data->repo->pool, kv->id ) );
      break;
      case REPOKEY_TYPE_DIR:
        value = Swig_Null;
      break;
      case REPOKEY_TYPE_STR:
        value = Swig_String( kv->str );
      break;
      case REPOKEY_TYPE_IDARRAY:
        if (Swig_Test(value))
	  value = Swig_Array();  /* create new Array on first call */
        if (data->localpool)
	  Swig_Append( value, Swig_String( stringpool_id2str( &data->spool, kv->id ) ) );
	else
	  Swig_Append( value, Swig_String( id2str( data->repo->pool, kv->id ) ) );
	if (kv->eof)
	  break;  /* yield ! */
	return 0; /* continue loop */
      break;
      case REPOKEY_TYPE_REL_IDARRAY:
        value = Swig_Null;
      break;
      case REPOKEY_TYPE_DIRSTRARRAY:
        value = Swig_String( repodata_dir2str(data,kv->id, kv->str) );
      break;
      case REPOKEY_TYPE_DIRNUMNUMARRAY:
        value = Swig_Array();
	Swig_Append( value, Swig_String( repodata_dir2str(data, kv->id, 0) ) );
	Swig_Append( value, Swig_Int(kv->num) );
	Swig_Append( value, Swig_Int(kv->num2) );
      break;
      case REPOKEY_TYPE_MD5:
      case REPOKEY_TYPE_SHA1:
      case REPOKEY_TYPE_SHA256:
        value = Swig_String( repodata_chk2str(data, key->type, (unsigned char *)kv->str));
      break;
      case REPOKEY_TYPE_COUNTED:
	value = Swig_String( kv->eof == 0 ? "open" : kv->eof == 1 ? "next" : "close" );
      break;
      default:
        value = Swig_Null;
      break;
    }

  Swig_Type result = Swig_Array();
  Swig_Append( result, Swig_String( id2str( data->repo->pool, key->name ) ) );
  Swig_Append( result, value );
#if defined(SWIGRUBY)
  rb_yield( result );
#endif

  return 0;
}


/*
 * searching for an attribute of a (x)solvable ('yield' in Ruby)
 */

static int
xsolvable_attr_lookup_callback( void *cbdata, Solvable *s, Repodata *data, Repokey *key, KeyValue *kv )
{
  Swig_Type *result = (Swig_Type *)cbdata;
  
  /*
   * !! keep the order of case statements according to knownid.h !!
   */
 
  switch( key->type )
    {
      case REPOKEY_TYPE_VOID:
        *result = Swig_True;
      break;
      case REPOKEY_TYPE_CONSTANT:
        *result = Swig_Int( key->size );
      break;
      case REPOKEY_TYPE_CONSTANTID:
        *result = Swig_Int( key->size );
      break;
      case REPOKEY_TYPE_ID:
        if (data->localpool)
	  *result = Swig_String( stringpool_id2str( &data->spool, kv->id ) );
	else
	  *result = Swig_String( id2str( data->repo->pool, kv->id ) );
      break;
      case REPOKEY_TYPE_NUM:
        *result = Swig_Int( kv->num );
      break;
      case REPOKEY_TYPE_U32:
        *result = Swig_Int( kv->num );
      break;
      case REPOKEY_TYPE_DIR:
        *result = Swig_Null; /*FIXME*/
      break;
      case REPOKEY_TYPE_STR:
        *result = Swig_String( kv->str );
      break;
      case REPOKEY_TYPE_IDARRAY:
        if (Swig_Test(*result))
	  *result = Swig_Array();  /* create new Array on first call */
        if (data->localpool)
	  Swig_Append( *result, Swig_String( stringpool_id2str( &data->spool, kv->id ) ) );
	else
	  Swig_Append( *result, Swig_String( id2str( data->repo->pool, kv->id ) ) );
	return kv->eof?1:0;
      break;
      case REPOKEY_TYPE_REL_IDARRAY:
        *result = Swig_Null; /*FIXME*/
      break;
      case REPOKEY_TYPE_DIRSTRARRAY:
        *result = Swig_Null; /*FIXME*/
      break;
      case REPOKEY_TYPE_DIRNUMNUMARRAY:
        *result = Swig_Null; /*FIXME*/
      break;
      case REPOKEY_TYPE_MD5:
        *result = Swig_Null; /*FIXME*/
      break;
      case REPOKEY_TYPE_SHA1:
        *result = Swig_Null; /*FIXME*/
      break;
      case REPOKEY_TYPE_SHA256:
        *result = Swig_Null; /*FIXME*/
      break;
      default:
        *result = Swig_Null;
        return 0;
      break;
    }
  return 1;
}


%}


%nodefault _Solvable;
%rename(Solvable) _Solvable;
typedef struct _Solvable {} XSolvable; /* expose XSolvable as 'Solvable' */


%extend XSolvable {

  %constant int KIND_PACKAGE  = KIND_PACKAGE;
  %constant int KIND_PRODUCT  = KIND_PRODUCT;
  %constant int KIND_PATCH    = KIND_PATCH;
  %constant int KIND_SOURCE   = KIND_SOURCE;
  %constant int KIND_PATTERN  = KIND_PATTERN;
  %constant int KIND_NOSOURCE = KIND_PATTERN;
	    
  XSolvable( Repo *repo, const char *name, const char *evr, const char *arch = NULL )
  { return xsolvable_create( repo, name, evr, arch ); }
  ~XSolvable()
  { return xsolvable_free( $self ); }
  
  Repo *repo()
  { return xsolvable_solvable($self)->repo; }

  const char *name()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->name ); }
  const char *arch()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->arch ); }
  const char *evr()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->evr ); }
  const char *vendor()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->vendor ); }
#if defined(SWIGRUBY)
  %rename( "vendor=" ) set_vendor( const char *vendor );
#endif
  void set_vendor(const char *vendor)
  { xsolvable_solvable($self)->vendor = str2id( $self->pool, vendor, 1 ); }

#if defined(SWIGRUBY)
  %rename("to_s") asString();
#endif
  const char *asString()
  {
    if ( $self->id == ID_NULL ) return "";
    return solvable2str( $self->pool, xsolvable_solvable( $self ) );
  }

#if defined(SWIGRUBY)
  %alias equal "==";
  %typemap(out) int equal
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
  int equal( XSolvable *xs )
  { return xsolvable_equal( $self, xs); }

#if defined(SWIGRUBY)
  %alias cmp "<=>";
#endif
  int cmp( XSolvable *xs )
  {
    Solvable *s1 = xsolvable_solvable( $self );
    Solvable *s2 = xsolvable_solvable( xs );
    const char *n1 = 0, *n2 = 0;
    int i = 0;

    if (($self->pool != xs->pool)
        || (s1->name != s2->name))
      {
        n1 = id2str( $self->pool, s1->name );
	n2 = id2str( xs->pool, s2->name );
	i = strcmp( n1, n2 );
      }
    if (i == 0) /* names are equal */
      {
        if ($self->pool == xs->pool)
	  i = evrcmp( $self->pool, s1->evr, s2->evr, EVRCMP_COMPARE );
	else
	{
          n1 = id2str( $self->pool, s1->evr );
	  n2 = id2str( xs->pool, s2->evr );
	  i = strcmp( n1, n2 );
	}
      }
    return i;
  }
  
  /*
   * Dependencies
   */
  Dependency *provides()
  { return dependency_new( $self, DEP_PRV ); }
  Dependency *requires()
  { return dependency_new( $self, DEP_REQ ); }
  Dependency *conflicts()
  { return dependency_new( $self, DEP_CON ); }
  Dependency *obsoletes()
  { return dependency_new( $self, DEP_OBS ); }
  Dependency *recommends()
  { return dependency_new( $self, DEP_REC ); }
  Dependency *suggests()
  { return dependency_new( $self, DEP_SUG ); }
  Dependency *supplements()
  { return dependency_new( $self, DEP_SUP ); }
  Dependency *enhances()
  { return dependency_new( $self, DEP_ENH ); }
  
#if defined(SWIGRUBY)
  %rename( "provides?" ) does_provide( const char *name );
  %rename( "provides_any?" ) does_provide_any( Array );
  %rename( "provides_all?" ) does_provide_all( Array );
  %typemap(out) int does_provide
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif

#if 0
  int does_provide( const char *name )
  { return dep_match_name( $self, DEP_PRV, name ); }
#if defined(SWIGRUBY)
  int does_provide( const char *regexp )
  { return dep_match_regexp( $self, DEP_PRV, regexp ); }
#endif
  int does_provide( const Relation *rel )
  { return dep_match_relation( $self, DEP_PRV, rel ); }
#endif

  /*
   * Attributes (from Repodata / Repokey)
   */


#if defined(SWIGRUBY)

  /*
   * access attribute via []
   */
   
  /* %rename is rejected by swig for [] */
  %alias attr "[]";
  VALUE attr( VALUE attrname )
#endif
#if defined(SWIGPYTHON)
  PyObject *attr( const char *name )
#endif
  {
#if defined(SWIGRUBY)
    char *name;

    if (SYMBOL_P(attrname)) {
      char *colon;
      name = rb_id2name( SYM2ID( attrname ) );
      colon = name;
      while ((colon = strchr( colon, '_'))) {
        *colon++ = ':';
      }
    }
    else
      name = StringValuePtr( attrname );
#endif
    if (!name)
      SWIG_exception( SWIG_ValueError, "Attribute name missing" );

    /* key existing in pool ? */
    Id key;
    key = str2id( $self->pool, name, 0);
    if (key == ID_NULL)
      SWIG_exception( SWIG_ValueError, "No such attribute name" );

    Swig_Type result = Swig_Null;
    Solvable *s = xsolvable_solvable($self);
    if (repo_lookup( s, key, xsolvable_attr_lookup_callback, &result ))
      return result;
fail:
    return Swig_Null;
  }
  
  /*
   * iterate over all attributes
   */

  void each_attr()
  {
    Solvable *s = xsolvable_solvable($self);
    Dataiterator di;
    dataiterator_init(&di, s->repo, $self->id, 0, 0, SEARCH_NO_STORAGE_SOLVABLE);
    while (dataiterator_step(&di))
      xsolvable_each_attr_callback( s, di.data, di.key, &di.kv );
  }


  /*
   * check existance of attribute
   */
   
#if defined(SWIGRUBY)
  %rename( "attr?" ) attr_exists( VALUE attrname );
  VALUE attr_exists( VALUE attrname )
#endif
#if defined(SWIGPYTHON)
  PyObject *attr_exists( const char *name )
#endif
  {
#if defined(SWIGRUBY)
    char *name;

    if (SYMBOL_P(attrname)) {
      char *colon;
      name = rb_id2name( SYM2ID( attrname ) );
      colon = name;
      while ((colon = strchr( colon, '_'))) {
        *colon++ = ':';
      }
    }
    else
      name = StringValuePtr( attrname );
#endif

    if (!name)
      return Swig_False;
    /* key existing in pool ? */
    Id key;
    key = str2id( $self->pool, name, 0);
    return (key == ID_NULL) ? Swig_False : Swig_True;
  }
}

