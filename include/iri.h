#ifndef IRI_H
#define IRI_H

  
extern void readapf107_(void);
extern void read_ig_rz_(void);
// Prototype for the IRI_SUB subroutine
extern void iri_sub_(int *jf, int *jmag, float *alati, float *along,
                     int *iyyyy, int *mmdd, float *dhour,
                     float *heibeg, float *heiend, float *heistp,
                     float *outf, float *oarr);

#endif /* IRI_H */